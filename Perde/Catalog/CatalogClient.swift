import Foundation

enum CatalogEndpoint {
    static let country = "tr"
    static let search = URL(string: "https://itunes.apple.com/search")!
    static let lookup = URL(string: "https://itunes.apple.com/lookup")!

    /// Marketing-tools v2 routes are requested alongside the live iTunes RSS charts.
    /// The v2 movie and TV routes currently time out or return 404.
    static let movieCharts = [
        URL(string: "https://rss.applemarketingtools.com/api/v2/tr/movies/top-movies/40/movies.json")!,
        URL(string: "https://itunes.apple.com/tr/rss/topmovies/limit=40/json")!,
    ]
    static let seriesCharts = [
        URL(string: "https://rss.applemarketingtools.com/api/v2/tr/tv-shows/top-tv-seasons/40/tv-seasons.json")!,
        URL(string: "https://itunes.apple.com/tr/rss/toptvseasons/limit=40/json")!,
    ]
}

struct CatalogClient: Sendable {
    let session: URLSession

    init(session: URLSession = CatalogClient.makeSession()) {
        self.session = session
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }

    func topMovies() async throws -> [CatalogItem] {
        try await loadChart(urls: CatalogEndpoint.movieCharts, kind: .movie)
    }

    func topSeries() async throws -> [CatalogItem] {
        try await loadChart(urls: CatalogEndpoint.seriesCharts, kind: .series)
    }

    func search(term: String) async throws -> [CatalogItem] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        async let movies = fetchSearch(term: trimmed, media: "movie", entity: "movie", assumed: .movie)
        async let series = fetchSearch(term: trimmed, media: "tvShow", entity: "tvSeason", assumed: .series)
        var movieHits = try await movies
        var seriesHits = try await series

        // `media=movie` currently returns an empty set from the Search API.
        // The same endpoint without that filter still includes feature films.
        if movieHits.isEmpty || seriesHits.isEmpty {
            let supplemental = try await fetchSearch(term: trimmed, media: nil, entity: nil, assumed: nil)
                .filter { titleMatches($0, term: trimmed) }
            if movieHits.isEmpty {
                movieHits = supplemental.filter { $0.kind == .movie }
            }
            if seriesHits.isEmpty {
                seriesHits = supplemental.filter { $0.kind == .series }
            }
        }

        return dedupe(movieHits + seriesHits)
    }

    func detail(id: String, fallbackKind: MediaKind) async throws -> CatalogDetail {
        guard let url = lookupURL(id: id) else {
            throw CatalogError.unavailable
        }
        let data = try await fetchData(from: url)
        let envelope = try JSONDecoder().decode(SearchEnvelope.self, from: data)
        let hit = envelope.results.first { $0.matches(id: id) } ?? envelope.results.first
        guard let hit, let detail = hit.catalogDetail(fallbackKind: fallbackKind) else {
            throw CatalogError.notFound
        }
        return detail
    }

    /// Requests every chart URL together. A usable list is returned as soon as one
    /// arrives, so a hung marketing-tools host does not block the live iTunes chart.
    private func loadChart(urls: [URL], kind: MediaKind) async throws -> [CatalogItem] {
        let outcome: Result<[CatalogItem], Error> = await withTaskGroup(of: ChartAttempt.self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    do {
                        let data = try await self.fetchData(from: url)
                        let items = try ChartDecoder.items(from: data, kind: kind)
                        return ChartAttempt(index: index, items: items, cancelled: false)
                    } catch {
                        return ChartAttempt(index: index, items: nil, cancelled: CatalogFailure.isCancellation(error))
                    }
                }
            }

            var emptyResult: ChartAttempt?
            var sawCancellation = false
            var pending = urls.count
            while let attempt = await group.next() {
                pending -= 1
                if let items = attempt.items, !items.isEmpty {
                    group.cancelAll()
                    return .success(items)
                }
                if attempt.items != nil {
                    if emptyResult == nil || attempt.index < (emptyResult?.index ?? Int.max) {
                        emptyResult = attempt
                    }
                } else if attempt.cancelled {
                    sawCancellation = true
                }
                if pending == 0 {
                    break
                }
            }

            if let emptyResult, let items = emptyResult.items {
                return .success(items)
            }
            if sawCancellation {
                return .failure(CancellationError())
            }
            return .failure(CatalogError.unavailable)
        }

        return try outcome.get()
    }

    private func fetchSearch(
        term: String,
        media: String?,
        entity: String?,
        assumed: MediaKind?
    ) async throws -> [CatalogItem] {
        guard let url = searchURL(term: term, media: media, entity: entity) else {
            throw CatalogError.unavailable
        }
        let data = try await fetchData(from: url)
        let envelope = try JSONDecoder().decode(SearchEnvelope.self, from: data)
        return envelope.results.compactMap { $0.catalogItem(assuming: assumed) }
    }

    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CatalogError.unavailable
        }
        return data
    }

    private func searchURL(term: String, media: String?, entity: String?) -> URL? {
        var components = URLComponents(url: CatalogEndpoint.search, resolvingAgainstBaseURL: false)
        var items = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "country", value: CatalogEndpoint.country),
            URLQueryItem(name: "limit", value: "50"),
        ]
        if let media {
            items.append(URLQueryItem(name: "media", value: media))
        }
        if let entity {
            items.append(URLQueryItem(name: "entity", value: entity))
        }
        components?.queryItems = items
        return components?.url
    }

    private func lookupURL(id: String) -> URL? {
        var components = URLComponents(url: CatalogEndpoint.lookup, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "country", value: CatalogEndpoint.country),
        ]
        return components?.url
    }

    /// Fold dotted and dotless i so a typed query still matches store titles.
    private func titleMatches(_ item: CatalogItem, term: String) -> Bool {
        let haystack = normalized("\(item.title) \(item.artistName)")
        let words = normalized(term)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 2 }
        guard !words.isEmpty else { return false }
        return words.allSatisfy { haystack.contains($0) }
    }

    private func normalized(_ text: String) -> String {
        let lowered = text.lowercased(with: Locale(identifier: "tr_TR"))
        let folded = lowered.folding(options: .diacriticInsensitive, locale: Locale(identifier: "tr_TR"))
        return folded.replacingOccurrences(of: "ı", with: "i")
    }

    private func dedupe(_ items: [CatalogItem]) -> [CatalogItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }
}

private struct ChartAttempt: Sendable {
    let index: Int
    let items: [CatalogItem]?
    let cancelled: Bool
}

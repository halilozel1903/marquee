import Foundation

enum CatalogFormatting {
    static func genre(from names: [String]) -> String? {
        let generic: Set<String> = [
            "movie", "movies", "film", "films",
            "tv show", "tv shows", "tv season", "tv seasons", "all",
        ]
        let cleaned = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let specific = cleaned.filter { !generic.contains($0.lowercased()) }
        let chosen = specific.isEmpty ? cleaned : specific
        let text = chosen.prefix(2).joined(separator: " · ")
        return text.isEmpty ? nil : text
    }

    static func date(from raw: String?) -> Date? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: trimmed) {
            return date
        }
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: trimmed) {
            return date
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: String(trimmed.prefix(10)))
    }

    static func display(date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .long, time: .omitted)
                .locale(Locale(identifier: "en_US"))
        )
    }

    static func posterURL(from raw: String?) -> URL? {
        guard var raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        if let regex = try? NSRegularExpression(pattern: #"\d+x\d+bb"#) {
            let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
            if let match = regex.matches(in: raw, range: range).last,
               let swiftRange = Range(match.range, in: raw) {
                raw.replaceSubrange(swiftRange, with: "600x900bb")
            }
        }
        return URL(string: raw)
    }

    static func synopsis(_ long: String?, _ short: String?) -> String? {
        let preferred = (long?.isEmpty == false) ? long : short
        guard let preferred else { return nil }
        let cleaned = plain(preferred)
        return cleaned.isEmpty ? nil : cleaned
    }

    static func plain(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ChartDecoder {
    static func items(from data: Data, kind: MediaKind) throws -> [CatalogItem] {
        let root = try JSONValue.parse(data: data)
        guard let feed = root["feed"] else {
            throw CatalogError.unavailable
        }

        if let resultsValue = feed["results"] {
            guard let results = resultsValue.array else {
                throw CatalogError.unavailable
            }
            return results.enumerated().compactMap { index, item in
                marketingItem(item, rank: index + 1, kind: kind)
            }
        }

        guard let entry = feed["entry"] else {
            return []
        }
        let values: [JSONValue]
        if let many = entry.array {
            values = many
        } else if case .object = entry {
            values = [entry]
        } else {
            return []
        }

        let parsed = values.enumerated().compactMap { index, item in
            rssItem(item, rank: index + 1, kind: kind)
        }
        if !values.isEmpty, parsed.isEmpty {
            throw CatalogError.unavailable
        }
        return parsed
    }

    private static func marketingItem(_ item: JSONValue, rank: Int, kind: MediaKind) -> CatalogItem? {
        guard let id = item["id"]?.text, !id.isEmpty else { return nil }
        guard let title = item["name"]?.text, !title.isEmpty else { return nil }
        let genres = item["genres"]?.array?.compactMap { $0["name"]?.text } ?? []
        return CatalogItem(
            id: id,
            title: title,
            artistName: item["artistName"]?.text ?? "",
            genre: CatalogFormatting.genre(from: genres),
            releaseDate: CatalogFormatting.date(from: item["releaseDate"]?.text),
            synopsis: nil,
            artworkURL: CatalogFormatting.posterURL(from: item["artworkUrl100"]?.text),
            kind: kind,
            rank: rank
        )
    }

    private static func rssItem(_ entry: JSONValue, rank: Int, kind: MediaKind) -> CatalogItem? {
        guard let id = entry["id"]?["attributes"]?["im:id"]?.text, !id.isEmpty else { return nil }
        guard let title = entry["im:name"]?.label ?? entry["im:name"]?.text, !title.isEmpty else { return nil }
        return CatalogItem(
            id: id,
            title: CatalogFormatting.plain(title),
            artistName: CatalogFormatting.plain(entry["im:artist"]?.label ?? ""),
            genre: CatalogFormatting.genre(from: genreNames(in: entry)),
            releaseDate: CatalogFormatting.date(from: entry["im:releaseDate"]?.label),
            synopsis: CatalogFormatting.synopsis(entry["summary"]?.label, nil),
            artworkURL: CatalogFormatting.posterURL(from: artworkString(in: entry)),
            kind: kind,
            rank: rank
        )
    }

    private static func genreNames(in entry: JSONValue) -> [String] {
        let categories: [JSONValue]
        if let many = entry["category"]?.array {
            categories = many
        } else if let one = entry["category"] {
            categories = [one]
        } else {
            return []
        }
        return categories.compactMap { category in
            category["attributes"]?["term"]?.text
                ?? category["attributes"]?["label"]?.text
                ?? category.label
        }
    }

    private static func artworkString(in entry: JSONValue) -> String? {
        guard let images = entry["im:image"]?.array, !images.isEmpty else { return nil }
        let best = images.max { lhs, rhs in
            height(lhs) < height(rhs)
        }
        return best?.label ?? best?.text
    }

    private static func height(_ image: JSONValue) -> Int {
        Int(image["attributes"]?["height"]?.text ?? "") ?? 0
    }
}

enum JSONValue {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    static func parse(data: Data) throws -> JSONValue {
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return wrap(object)
    }

    private static func wrap(_ any: Any) -> JSONValue {
        switch any {
        case let value as String:
            return .string(value)
        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                return .bool(value.boolValue)
            }
            return .number(value.doubleValue)
        case let value as [Any]:
            return .array(value.map(wrap))
        case let value as [String: Any]:
            return .object(value.mapValues(wrap))
        default:
            return .null
        }
    }

    subscript(_ key: String) -> JSONValue? {
        guard case .object(let object) = self else { return nil }
        return object[key]
    }

    var array: [JSONValue]? {
        guard case .array(let values) = self else { return nil }
        return values
    }

    var text: String? {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            guard value.rounded(.towardZero) == value,
                  value <= Double(Int.max),
                  value >= Double(Int.min) else {
                return String(value)
            }
            return String(Int(value))
        default:
            return nil
        }
    }

    var label: String? {
        self["label"]?.text
    }
}

struct SearchEnvelope: Decodable {
    let results: [SearchHit]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let wrapped = try container.decode([FailableSearchHit].self, forKey: .results)
        results = wrapped.compactMap(\.value)
    }

    private enum CodingKeys: String, CodingKey {
        case results
    }
}

private struct FailableSearchHit: Decodable {
    let value: SearchHit?

    init(from decoder: Decoder) throws {
        value = try? SearchHit(from: decoder)
    }
}

struct SearchHit: Decodable {
    let wrapperType: String?
    let kind: String?
    let collectionType: String?
    let trackId: Int?
    let collectionId: Int?
    let trackName: String?
    let trackCensoredName: String?
    let collectionName: String?
    let collectionCensoredName: String?
    let artistName: String?
    let artworkUrl100: String?
    let primaryGenreName: String?
    let releaseDate: String?
    let longDescription: String?
    let shortDescription: String?
    let trackViewUrl: String?
    let collectionViewUrl: String?
    let contentAdvisoryRating: String?

    func catalogItem(assuming assumed: MediaKind?) -> CatalogItem? {
        guard let resolved = resolvedKind(assuming: assumed) else { return nil }
        let id: String?
        let title: String?
        switch resolved {
        case .movie:
            id = trackId.map(String.init)
            title = nonempty(trackName) ?? nonempty(trackCensoredName)
        case .series:
            id = collectionId.map(String.init)
            title = nonempty(collectionName) ?? nonempty(collectionCensoredName)
        }
        guard let id, let title else { return nil }
        return CatalogItem(
            id: id,
            title: CatalogFormatting.plain(title),
            artistName: CatalogFormatting.plain(artistName ?? ""),
            genre: primaryGenreName.flatMap { CatalogFormatting.genre(from: [$0]) },
            releaseDate: CatalogFormatting.date(from: releaseDate),
            synopsis: CatalogFormatting.synopsis(longDescription, shortDescription),
            artworkURL: CatalogFormatting.posterURL(from: artworkUrl100),
            kind: resolved,
            rank: nil
        )
    }

    func catalogDetail(fallbackKind: MediaKind) -> CatalogDetail? {
        guard let item = catalogItem(assuming: fallbackKind) ?? catalogItem(assuming: nil) else {
            return nil
        }
        let storeRaw = nonempty(trackViewUrl) ?? nonempty(collectionViewUrl)
        return CatalogDetail(
            id: item.id,
            title: item.title,
            artistName: item.artistName,
            genre: item.genre,
            releaseDate: item.releaseDate,
            synopsis: item.synopsis,
            artworkURL: item.artworkURL,
            storeURL: storeRaw.flatMap(URL.init(string:)),
            contentRating: nonempty(contentAdvisoryRating),
            kind: item.kind
        )
    }

    func matches(id: String) -> Bool {
        if let trackId, String(trackId) == id { return true }
        if let collectionId, String(collectionId) == id { return true }
        return false
    }

    private func resolvedKind(assuming assumed: MediaKind?) -> MediaKind? {
        if kind == "feature-movie" {
            return .movie
        }
        if collectionType == "TV Season" {
            return .series
        }
        if assumed == .movie,
           kind == nil,
           trackId != nil,
           nonempty(trackName) != nil || nonempty(trackCensoredName) != nil {
            return .movie
        }
        if assumed == .series,
           collectionId != nil,
           nonempty(collectionName) != nil || nonempty(collectionCensoredName) != nil,
           kind != "feature-movie",
           kind != "tv-episode",
           kind != "song",
           kind != "podcast" {
            return .series
        }
        return nil
    }

    private func nonempty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

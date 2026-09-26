import Foundation

enum MediaKind: String, Hashable, Sendable {
    case movie
    case series

    var title: String {
        switch self {
        case .movie:
            "Movie"
        case .series:
            "Series"
        }
    }
}

struct CatalogItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let artistName: String
    let genre: String?
    let releaseDate: Date?
    let synopsis: String?
    let artworkURL: URL?
    let kind: MediaKind
    let rank: Int?
}

struct CatalogDetail: Hashable, Sendable {
    let id: String
    let title: String
    let artistName: String
    let genre: String?
    let releaseDate: Date?
    let synopsis: String?
    let artworkURL: URL?
    /// Movies use the lookup `trackViewUrl`. Seasons use `collectionViewUrl`.
    let storeURL: URL?
    let contentRating: String?
    let kind: MediaKind
}

enum CatalogError: Error, Equatable {
    case unavailable
    case notFound
}

enum CatalogFailure {
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }
        return false
    }
}

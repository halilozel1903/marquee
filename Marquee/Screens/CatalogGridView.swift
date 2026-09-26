import SwiftUI

struct CatalogGridView: View {
    let kind: MediaKind

    @Environment(\.catalogClient) private var client
    @State private var phase: SectionPhase = .loading

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                PageHeader(title: title, subtitle: subtitle)
                content
            }
            .padding(.horizontal, CinemaTheme.horizontalPadding)
            .padding(.top, CinemaTheme.topPadding)
            .padding(.bottom, CinemaTheme.bottomPadding)
        }
        .cinemaScreen()
        .navigationDestination(for: CatalogItem.self) { item in
            DetailView(item: item)
        }
        .task {
            await load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            LoadingStateView()
        case .failed:
            ErrorStateView(retry: { Task { await load() } })
        case .empty:
            EmptyStateView(
                symbol: "film",
                title: "Nothing on this chart",
                message: emptyMessage
            )
        case .loaded(let items):
            PosterGrid(items: items)
        }
    }

    private var title: String {
        switch kind {
        case .movie:
            "Movies"
        case .series:
            "Series"
        }
    }

    private var subtitle: String {
        switch kind {
        case .movie:
            "The current top films in the Turkey store."
        case .series:
            "The current top series in the Turkey store."
        }
    }

    private var emptyMessage: String {
        switch kind {
        case .movie:
            "The Turkey store has no films on the top movies chart right now."
        case .series:
            "The Turkey store has no series on the top series chart right now."
        }
    }

    private func load() async {
        phase = .loading
        do {
            let items = try await fetch()
            phase = items.isEmpty ? .empty : .loaded(items)
        } catch {
            guard !CatalogFailure.isCancellation(error) else { return }
            phase = .failed
        }
    }

    private func fetch() async throws -> [CatalogItem] {
        switch kind {
        case .movie:
            try await client.topMovies()
        case .series:
            try await client.topSeries()
        }
    }
}

import SwiftUI

struct CatalogGridView: View {
    let kind: MediaKind

    @Environment(\.catalogClient) private var client
    @FocusState private var focusedID: String?
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
        .scrollClipDisabled()
        .cinemaScreen()
        .navigationDestination(for: CatalogItem.self) { item in
            DetailView(item: item)
        }
        .defaultFocus($focusedID, preferredID)
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
            PosterGrid(items: items, focusedID: $focusedID)
        }
    }

    private var preferredID: String? {
        if case .loaded(let items) = phase, let id = items.first?.id {
            return id
        }
        return nil
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
            if focusedID == nil {
                focusedID = items.first?.id
            }
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

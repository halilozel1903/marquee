import SwiftUI

struct SearchView: View {
    @Environment(\.catalogClient) private var client
    @FocusState private var focusedID: String?
    @State private var query = ""
    @State private var phase: SearchPhase = .prompt
    @State private var retryToken = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                PageHeader(
                    title: "Search",
                    subtitle: "Find a movie or series in the Turkey store."
                )
                results
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
        .searchable(text: $query, prompt: "Movie or series name")
        .defaultFocus($focusedID, preferredID)
        .task(id: searchToken) {
            await runSearch()
        }
    }

    private var preferredID: String? {
        if case .results(let items) = phase {
            return items.first?.id
        }
        return nil
    }

    @ViewBuilder
    private var results: some View {
        switch phase {
        case .prompt:
            EmptyStateView(
                symbol: "magnifyingglass",
                title: "Search the catalog",
                message: "Move to Search and enter at least two letters. Results update from the Turkey store as you type."
            )
        case .loading:
            LoadingStateView(
                title: "Searching",
                message: "Looking through the Turkey store."
            )
        case .failed:
            ErrorStateView(
                title: "Search didn't finish",
                message: "The Apple catalog didn't respond. Check the connection and try again.",
                retry: { retryToken += 1 }
            )
        case .empty:
            EmptyStateView(
                symbol: "magnifyingglass",
                title: "No matches",
                message: "Nothing in the Turkey store matches “\(trimmedQuery)”."
            )
        case .results(let items):
            VStack(alignment: .leading, spacing: 8) {
                Text(resultCount(items.count))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                PosterGrid(items: items, showsKind: true, focusedID: $focusedID)
            }
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchToken: String {
        "\(trimmedQuery)|\(retryToken)"
    }

    private func resultCount(_ count: Int) -> String {
        count == 1 ? "1 title" : "\(count) titles"
    }

    private func runSearch() async {
        let term = trimmedQuery
        guard term.count >= 2 else {
            phase = .prompt
            return
        }

        phase = .loading
        do {
            try await Task.sleep(for: .milliseconds(350))
            let items = try await client.search(term: term)
            guard !Task.isCancelled else { return }
            phase = items.isEmpty ? .empty : .results(items)
        } catch {
            guard !CatalogFailure.isCancellation(error) else { return }
            phase = .failed
        }
    }
}

private enum SearchPhase {
    case prompt
    case loading
    case results([CatalogItem])
    case empty
    case failed
}

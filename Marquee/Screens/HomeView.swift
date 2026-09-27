import SwiftUI

struct HomeView: View {
    @Environment(\.catalogClient) private var client
    @FocusState private var focusedID: String?
    @State private var movies: SectionPhase = .loading
    @State private var series: SectionPhase = .loading

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                PageHeader(
                    eyebrow: "TURKEY STORE",
                    title: "Marquee",
                    subtitle: "Movies and series at the top of the Turkey chart."
                )
                .padding(.bottom, 12)

                section(
                    title: "Top Movies",
                    phase: movies,
                    emptyMessage: "No films are charting in the Turkey store right now.",
                    retry: { Task { await loadMovies() } }
                )
                section(
                    title: "Top Series",
                    phase: series,
                    emptyMessage: "No series are charting in the Turkey store right now.",
                    retry: { Task { await loadSeries() } }
                )
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
            await loadAll()
        }
    }

    @ViewBuilder
    private func section(
        title: String,
        phase: SectionPhase,
        emptyMessage: String,
        retry: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.weight(.semibold))

            switch phase {
            case .loading:
                LoadingStateView()
            case .failed:
                ErrorStateView(retry: retry)
            case .empty:
                EmptyStateView(
                    symbol: "film",
                    title: "Nothing on this chart",
                    message: emptyMessage
                )
            case .loaded(let items):
                PosterRail(items: items, focusedID: $focusedID)
            }
        }
    }

    private var preferredID: String? {
        if case .loaded(let items) = movies, let id = items.first?.id {
            return id
        }
        if case .loaded(let items) = series, let id = items.first?.id {
            return id
        }
        return nil
    }

    private func loadAll() async {
        async let movieLoad: Void = loadMovies()
        async let seriesLoad: Void = loadSeries()
        _ = await (movieLoad, seriesLoad)
    }

    private func loadMovies() async {
        movies = .loading
        do {
            let items = try await client.topMovies()
            movies = items.isEmpty ? .empty : .loaded(items)
            if focusedID == nil {
                focusedID = items.first?.id
            }
        } catch {
            guard !CatalogFailure.isCancellation(error) else { return }
            movies = .failed
        }
    }

    private func loadSeries() async {
        series = .loading
        do {
            let items = try await client.topSeries()
            series = items.isEmpty ? .empty : .loaded(items)
            if focusedID == nil {
                focusedID = items.first?.id
            }
        } catch {
            guard !CatalogFailure.isCancellation(error) else { return }
            series = .failed
        }
    }
}

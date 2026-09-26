import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                CatalogGridView(kind: .movie)
            }
            .tabItem {
                Label("Movies", systemImage: "film.fill")
            }

            NavigationStack {
                CatalogGridView(kind: .series)
            }
            .tabItem {
                Label("Series", systemImage: "tv.fill")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
        .tint(CinemaTheme.accent)
    }
}

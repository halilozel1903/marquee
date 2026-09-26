import SwiftUI

struct PosterRail: View {
    let items: [CatalogItem]
    var showsKind = false

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 40) {
                ForEach(items) { item in
                    PosterLink(item: item, showsKind: showsKind)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 32)
        }
        .scrollClipDisabled()
    }
}

struct PosterGrid: View {
    let items: [CatalogItem]
    var showsKind = false

    private let columns = [
        GridItem(.adaptive(minimum: CinemaTheme.posterWidth), spacing: 48),
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 56) {
            ForEach(items) { item in
                PosterLink(item: item, showsKind: showsKind)
            }
        }
        .padding(.vertical, 24)
        .scrollClipDisabled()
    }
}

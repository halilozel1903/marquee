import SwiftUI

struct PosterRail: View {
    let items: [CatalogItem]
    var showsKind = false
    var focusedID: FocusState<String?>.Binding

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 28) {
                ForEach(items) { item in
                    PosterLink(item: item, showsKind: showsKind, focusedID: focusedID)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 36)
        }
        .scrollClipDisabled()
        .focusSection()
    }
}

struct PosterGrid: View {
    let items: [CatalogItem]
    var showsKind = false
    var focusedID: FocusState<String?>.Binding

    private let columns = Array(
        repeating: GridItem(.fixed(CinemaTheme.posterWidth + 36), spacing: 36),
        count: 4
    )

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 40) {
            ForEach(items) { item in
                PosterLink(item: item, showsKind: showsKind, focusedID: focusedID)
            }
        }
        .padding(.vertical, 28)
        .focusSection()
    }
}

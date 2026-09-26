import SwiftUI

struct PosterCard: View {
    let item: CatalogItem
    var showsKind = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                artwork
                if let rank = item.rank {
                    Text("\(rank)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(CinemaTheme.accent)
                        .clipShape(Capsule())
                        .padding(14)
                }
                if showsKind {
                    Text(item.kind.title)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.72))
                        .clipShape(Capsule())
                        .padding(14)
                        .frame(
                            width: CinemaTheme.posterWidth,
                            height: CinemaTheme.posterHeight,
                            alignment: .bottomLeading
                        )
                }
            }
            .frame(width: CinemaTheme.posterWidth, height: CinemaTheme.posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(item.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: CinemaTheme.posterWidth, alignment: .leading)

            if !item.artistName.isEmpty {
                Text(item.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: CinemaTheme.posterWidth, alignment: .leading)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var artwork: some View {
        AsyncImage(url: item.artworkURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                placeholder
            default:
                placeholder
                    .overlay(ProgressView())
            }
        }
        .frame(width: CinemaTheme.posterWidth, height: CinemaTheme.posterHeight)
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            CinemaTheme.raised
            Image(systemName: "film")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilityText: String {
        var parts = [item.title]
        if !item.artistName.isEmpty {
            parts.append(item.artistName)
        }
        if let genre = item.genre {
            parts.append(genre)
        }
        return parts.joined(separator: ", ")
    }
}

struct PosterLink: View {
    let item: CatalogItem
    var showsKind = false

    var body: some View {
        NavigationLink(value: item) {
            PosterCard(item: item, showsKind: showsKind)
        }
        .buttonStyle(.card)
    }
}

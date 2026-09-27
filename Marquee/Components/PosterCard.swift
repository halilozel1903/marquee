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

}

struct PosterLink: View {
    let item: CatalogItem
    var showsKind = false
    var focusedID: FocusState<String?>.Binding

    var body: some View {
        NavigationLink(value: item) {
            PosterCard(item: item, showsKind: showsKind)
        }
        .buttonStyle(PosterFocusStyle())
        .focused(focusedID, equals: item.id as String?)
        .zIndex(focusedID.wrappedValue == item.id ? 1 : 0)
        .accessibilityLabel(accessibilityText)
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

/// Card-style buttons inside a tvOS scroll view clip their focus effect and stop
/// receiving the remote. This style draws the highlight itself.
private struct PosterFocusStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PosterFocusLabel(configuration: configuration)
    }
}

private struct PosterFocusLabel: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(isFocused ? 0.08 : 0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(CinemaTheme.accent, lineWidth: isFocused ? 5 : 0)
            )
            .scaleEffect(isFocused || configuration.isPressed ? 1.06 : 1)
            .shadow(color: .black.opacity(isFocused ? 0.55 : 0), radius: isFocused ? 28 : 0, y: isFocused ? 16 : 0)
            .animation(.easeOut(duration: 0.16), value: isFocused)
    }
}

import SwiftUI

struct DetailView: View {
    let item: CatalogItem

    @Environment(\.catalogClient) private var client
    @Environment(\.openURL) private var openURL
    @FocusState private var isStoreFocused: Bool
    @State private var detail: CatalogDetail?
    @State private var phase: DetailPhase = .loading
    @State private var retryToken = 0

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 72) {
                artwork
                details
            }
            .padding(.horizontal, CinemaTheme.horizontalPadding)
            .padding(.top, 36)
            .padding(.bottom, CinemaTheme.bottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollClipDisabled()
        .cinemaScreen()
        .task(id: "\(item.id)|\(retryToken)") {
            await load()
        }
    }

    private var artwork: some View {
        AsyncImage(url: displayArtwork) { imagePhase in
            switch imagePhase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                artworkPlaceholder
            default:
                artworkPlaceholder
                    .overlay(ProgressView())
            }
        }
        .frame(width: 420, height: 630)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var artworkPlaceholder: some View {
        ZStack {
            CinemaTheme.raised
            Image(systemName: "film")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(eyebrow)
                .font(.subheadline.weight(.semibold))
                .tracking(2.2)
                .foregroundStyle(CinemaTheme.accent)

            Text(displayTitle)
                .font(.system(size: 56, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)

            if !displayArtist.isEmpty {
                Text(displayArtist)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if !metadata.isEmpty {
                Text(metadata)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            synopsisBlock

            if let storeURL = detail?.storeURL {
                Button {
                    openURL(storeURL)
                } label: {
                    Text("View in the Store")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(CinemaTheme.button)
                .focused($isStoreFocused)
                .padding(.top, 8)
                .onAppear { isStoreFocused = true }
            }
        }
        .frame(maxWidth: 900, alignment: .leading)
    }

    @ViewBuilder
    private var synopsisBlock: some View {
        switch phase {
        case .loading:
            VStack(alignment: .leading, spacing: 16) {
                if let synopsis = displaySynopsis {
                    Text(synopsis)
                        .font(.title3)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 16) {
                    ProgressView()
                    Text("Loading the store listing.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        case .failed:
            VStack(alignment: .leading, spacing: 12) {
                if let synopsis = item.synopsis {
                    Text(synopsis)
                        .font(.title3)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ErrorStateView(
                    title: "Couldn't load details",
                    message: "The store listing didn't come through. Check the connection and try again.",
                    retry: { retryToken += 1 }
                )
            }
        case .missing:
            VStack(alignment: .leading, spacing: 12) {
                if let synopsis = item.synopsis {
                    Text(synopsis)
                        .font(.title3)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                EmptyStateView(
                    symbol: "film",
                    title: "Unavailable in this store",
                    message: "This title has no Turkey store listing to open."
                )
            }
        case .loaded:
            Text(displaySynopsis ?? "No synopsis is available for this title.")
                .font(.title3)
                .foregroundStyle(displaySynopsis == nil ? .secondary : .primary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var displayTitle: String {
        detail?.title ?? item.title
    }

    private var displayArtist: String {
        let name = detail?.artistName ?? item.artistName
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayArtwork: URL? {
        detail?.artworkURL ?? item.artworkURL
    }

    private var displaySynopsis: String? {
        detail?.synopsis ?? item.synopsis
    }

    private var eyebrow: String {
        if let genre = detail?.genre ?? item.genre, !genre.isEmpty {
            return genre.uppercased()
        }
        return item.kind.title.uppercased()
    }

    private var metadata: String {
        var parts: [String] = []
        if let date = detail?.releaseDate ?? item.releaseDate {
            parts.append(CatalogFormatting.display(date: date))
        }
        if let rating = detail?.contentRating, !rating.isEmpty {
            parts.append(rating)
        }
        parts.append(item.kind.title)
        return parts.joined(separator: "  ·  ")
    }

    private func load() async {
        phase = .loading
        do {
            detail = try await client.detail(id: item.id, fallbackKind: item.kind)
            phase = .loaded
        } catch let error as CatalogError where error == .notFound {
            phase = .missing
        } catch {
            guard !CatalogFailure.isCancellation(error) else { return }
            phase = .failed
        }
    }
}

private enum DetailPhase {
    case loading
    case loaded
    case failed
    case missing
}

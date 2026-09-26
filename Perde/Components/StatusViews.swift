import SwiftUI

enum SectionPhase {
    case loading
    case loaded([CatalogItem])
    case empty
    case failed
}

struct LoadingStateView: View {
    var title = "Loading titles"
    var message = "Fetching the latest from the Apple catalog."

    var body: some View {
        VStack(spacing: 22) {
            ProgressView()
                .scaleEffect(1.4)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 640)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}

struct ErrorStateView: View {
    var title = "Couldn't load titles"
    var message = "The Apple catalog didn't respond. Check the connection and try again."
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(CinemaTheme.accent)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 680)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(CinemaTheme.button)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: symbol)
                .font(.system(size: 48))
                .foregroundStyle(CinemaTheme.accent)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 720)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

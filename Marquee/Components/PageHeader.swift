import SwiftUI

struct PageHeader: View {
    var eyebrow: String?
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.subheadline.weight(.semibold))
                    .tracking(2.5)
                    .foregroundStyle(CinemaTheme.accent)
            }
            Text(title)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 860, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

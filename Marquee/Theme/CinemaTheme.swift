import SwiftUI

enum CinemaTheme {
    static let accent = Color(red: 0.729, green: 0.580, blue: 0.345)
    static let button = Color(red: 0.42, green: 0.30, blue: 0.14)
    static let raised = Color(red: 0.16, green: 0.14, blue: 0.15)
    static let posterWidth: CGFloat = 280
    static let posterHeight: CGFloat = 420
    static let horizontalPadding: CGFloat = 80
    static let topPadding: CGFloat = 28
    static let bottomPadding: CGFloat = 80

    static let background = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.09, blue: 0.10),
            Color(red: 0.05, green: 0.05, blue: 0.055),
            Color.black,
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct CinemaScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(CinemaTheme.background.ignoresSafeArea())
    }
}

extension View {
    func cinemaScreen() -> some View {
        modifier(CinemaScreen())
    }
}

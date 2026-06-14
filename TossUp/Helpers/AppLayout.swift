import SwiftUI

enum AppLayout {
    static let contentMaxWidth: CGFloat = 760
    static let quizMaxWidth: CGFloat = 820
    static let cornerRadius: CGFloat = 14
}

extension View {
    /// Centers content in wide macOS split-view columns.
    func contentColumn(maxWidth: CGFloat = AppLayout.contentMaxWidth) -> some View {
        modifier(ContentColumnModifier(maxWidth: maxWidth))
    }

    func cardStyle() -> some View {
        padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
    }
}

private struct ContentColumnModifier: ViewModifier {
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            content
                .frame(maxWidth: maxWidth)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

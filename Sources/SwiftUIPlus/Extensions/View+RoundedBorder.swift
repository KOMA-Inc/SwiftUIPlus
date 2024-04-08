import SwiftUI

public extension View {

    @ViewBuilder
    func roundedBorder(
        radius: CGFloat = .zero,
        color: Color = Color(.label),
        width: CGFloat = 1
    ) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(color, lineWidth: width)
        )
    }
}

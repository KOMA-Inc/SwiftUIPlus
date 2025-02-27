import SwiftUI

public extension View {

    @ViewBuilder func spacedFont(_ font: UIFont) -> some View {
        let pointSize = font.pointSize
        let font = Font(font)
        let spacing = (1.2 * pointSize - pointSize) / 2

        self
            .font(font)
            .lineSpacing(spacing)
    }
}

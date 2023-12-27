import SwiftUI

public extension View {

    @ViewBuilder
    func clipCorner(radius: CGFloat?) -> some View {
        if let radius {
            clipShape(RoundedRectangle(cornerRadius: radius))
        } else {
            self
        }
    }
}

import SwiftUI

public extension View {

    @ViewBuilder
    func clipCorner(radius: CGFloat?, corners: UIRectCorner = .allCorners) -> some View {
        if let radius {
            clipShape(RoundedCorner(cornerRadius: radius, corners: corners))
        } else {
            self
        }
    }
}

public struct RoundedCorner: Shape {

    let cornerRadius: CGFloat
    let corners: UIRectCorner

    public init(cornerRadius: CGFloat, corners: UIRectCorner = .allCorners) {
        self.cornerRadius = cornerRadius
        self.corners = corners
    }

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(
                width: cornerRadius,
                height: cornerRadius
            )
        )
        return Path(path.cgPath)
    }
}

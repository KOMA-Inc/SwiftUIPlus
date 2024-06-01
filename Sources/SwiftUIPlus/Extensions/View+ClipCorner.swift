import SwiftUI

public extension View {

    @ViewBuilder
    func clipCorner(radius: CGFloat = .zero, corners: UIRectCorner = .allCorners) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

@frozen public struct RoundedCorner: Shape {

    private var cornerRadiusWidth: CGFloat
    private var cornerRadiusHeight: CGFloat
    private let corners: UIRectCorner
    var insetAmount: CGFloat = .zero

    public init(cornerRadius: CGFloat, corners: UIRectCorner = .allCorners) {
        self.cornerRadiusWidth = cornerRadius
        self.cornerRadiusHeight = cornerRadius
        self.corners = corners
    }

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: CGRect(
                x: rect.minX + insetAmount,
                y: rect.minY + insetAmount,
                width: rect.width - 2 * insetAmount,
                height: rect.height - 2 * insetAmount
            ),
            byRoundingCorners: corners,
            cornerRadii: CGSize(
                width: cornerRadiusWidth,
                height: cornerRadiusWidth
            )
        )
        return Path(path.cgPath)
    }

    public var animatableData: CGSize.AnimatableData {
        get {
            CGSize.AnimatableData(cornerRadiusWidth, cornerRadiusHeight)
        }
        set {
            cornerRadiusWidth = newValue.first
            cornerRadiusHeight = newValue.second
        }
    }
}

extension RoundedCorner: InsettableShape {

    public func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount = amount
        return shape
    }

}

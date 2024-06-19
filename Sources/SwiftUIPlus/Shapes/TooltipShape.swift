import SwiftUI

private let tooltipTriangleSize = CGSize(width: 16, height: 8)

public struct TooltipShape: Shape {

    public enum TrianglePosition: Sendable {
        case leading
        case center
        case trailing
        /// 0 - 1
        case customPercent(CGFloat)
        case customLeadingOffset(CGFloat)
        case customTrailingOffset(CGFloat)

    }

    private var cornerRadius: CGFloat
    private let trianglePosition: TrianglePosition

    public init(
        cornerRadius: CGFloat,
        trianglePosition: TrianglePosition = .center
    ) {
        self.cornerRadius = cornerRadius
        self.trianglePosition = trianglePosition
    }

    private var triangleWidth: CGFloat {
        tooltipTriangleSize.width
    }

    private var triangleHeight: CGFloat {
        tooltipTriangleSize.height
    }

    private func triangleCenterXPosition(in rect: CGRect) -> CGFloat {
        let width = rect.width

        let offset: CGFloat = switch trianglePosition {
        case .leading:
                .zero
        case .center:
            width / 2
        case .trailing:
            width
        case .customPercent(let value):
            width * value
        case .customLeadingOffset(let offset):
            offset.clamped(to: 0...width)
        case .customTrailingOffset(let offset):
            (width - offset).clamped(to: 0...width)
        }

        return offset
    }

    public func path(in rect: CGRect) -> Path {
        let trianglePath = UIBezierPath()

        // Draw the triangle pointer
        trianglePath.move(
            to: CGPoint(
                x: max(triangleCenterXPosition(in: rect), rect.minX) - triangleWidth / 2,
                y: triangleHeight
            )
        )
        trianglePath.addLine(to: CGPoint(x: triangleCenterXPosition(in: rect), y: 0))
        trianglePath.addLine(to: CGPoint(x: triangleCenterXPosition(in: rect) + triangleWidth / 2, y: triangleHeight))

        let rectPath = UIBezierPath(
            roundedRect: CGRect(
                x: rect.minX,
                y: triangleHeight,
                width: rect.width,
                height: rect.height - triangleHeight
            ),
            byRoundingCorners: roundingCorners(
                in: rect,
                cornerRadius: cornerRadius
            ),
            cornerRadii: CGSize(
                width: cornerRadius,
                height: cornerRadius
            )
        )

        var path = Path()

        path.addPath(Path(trianglePath.cgPath))
        path.addPath(Path(rectPath.cgPath))

        return path
    }

    private func roundingCorners(
        in rect: CGRect,
        cornerRadius: CGFloat
    ) -> UIRectCorner {
        var corners: UIRectCorner = [.bottomLeft, .bottomRight]

        let width = rect.width
        let leftCorner = cornerRadius / 2
        let rightCorner = width - (cornerRadius / 2)

        let triangleCenterPosition = triangleCenterXPosition(in: rect)
        let triangleMinX = triangleCenterPosition - triangleWidth / 2
        let triangleMaxX = triangleCenterPosition + triangleWidth / 2

        if triangleMinX >= leftCorner {
            corners.insert(.topLeft)
        }

        if triangleMaxX <= rightCorner {
            corners.insert(.topRight)
        }

        return corners
    }
}

public extension View {
    func asTooltip(
        background: Color,
        cornerRadius: CGFloat,
        trianglePosition: TooltipShape.TrianglePosition = .center
    ) -> some View {
        padding(.top, tooltipTriangleSize.height)
            .background(background)
            .clipShape(TooltipShape(cornerRadius: cornerRadius, trianglePosition: trianglePosition))
    }
}

private extension Comparable {

    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

import SwiftUI

private let tooltipTriangleSize = CGSize(width: 16, height: 10)

public struct TooltipShape: Shape {

    public enum TrianglePosition: Sendable {
        case leading
        case center
        case trailing
        /// 0 - 1
        case custom(CGFloat)
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
        case .custom(let value):
            width * value
        }

        return offset
    }

    private var roundingCorners: UIRectCorner {
        switch trianglePosition {
        case .leading:
            [.topRight, .bottomLeft, .bottomRight]
        case .center:
                .allCorners
        case .trailing:
            [.topLeft, .bottomLeft, .bottomRight]
        case .custom(let value):
            if 0...0.09 ~= value {
                [.topRight, .bottomLeft, .bottomRight]
            } else if 0.91...1 ~= value {
                [.topLeft, .bottomLeft, .bottomRight]
            } else {
                .allCorners
            }
        }
    }

    public func path(in rect: CGRect) -> Path {

        var path = Path()

        // Draw the triangle pointer
        path.move(
            to: CGPoint(
                x: max(triangleCenterXPosition(in: rect), rect.minX) - triangleWidth / 2,
                y: triangleHeight
            )
        )
        path.addLine(to: CGPoint(x: triangleCenterXPosition(in: rect), y: 0))
        path.addLine(to: CGPoint(x: triangleCenterXPosition(in: rect) + triangleWidth / 2, y: triangleHeight))
        path.closeSubpath()

        let rectPath = UIBezierPath(
            roundedRect: CGRect(
                x: rect.minX,
                y: triangleHeight,
                width: rect.width,
                height: rect.height - triangleHeight
            ),
            byRoundingCorners: roundingCorners,
            cornerRadii: CGSize(
                width: cornerRadius,
                height: cornerRadius
            )
        )

        path.addPath(Path(rectPath.cgPath))

        return path
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

import SwiftUI

package func layout(
    sizes: [ViewDimensions],
    spacing: CGSize = .init(width: 10, height: 10),
    containerWidth: CGFloat,
    verticalAlignment: VerticalAlignment,
    horizontalAlignment: HorizontalAlignment
) -> [CGRect] {

    struct LineInfo {
        let rect: CGRect
        let dimensions: ViewDimensions
    }

    var lines: [[CGRect]] = []
    var currentLine: [LineInfo] = []
    var currentPosition: CGPoint = .zero

    func startNewline() {
        if currentPosition.x == .zero { return }

        guard let maxDimension = currentLine
            .map(\.dimensions)
            .max(by: { $0.height < $1.height }) else { return }

        let _currentLine: [CGRect] = currentLine.map { info in
            let yOffset = maxDimension[verticalAlignment] - info.dimensions[verticalAlignment]
            return CGRect(
                origin: CGPoint(
                    x: info.rect.minX,
                    y: info.rect.minY + yOffset
                ),
                size: info.rect.size
            )
        }

        lines.append(_currentLine)
        currentPosition.x = .zero
        currentPosition.y = _currentLine.union().maxY + spacing.height
        currentLine = []
    }

    for size in sizes {
        if currentPosition.x + size.width > containerWidth {
            startNewline()
        }

        currentLine.append(
            LineInfo(
                rect: CGRect(
                    origin: currentPosition,
                    size: CGSize(width: size.width, height: size.height)
                ),
                dimensions: size
            )
        )

        currentPosition.x += size.width + spacing.width
    }

    startNewline()

    if horizontalAlignment == .leading {
        return lines.flatMap { $0 }
    }

    guard let maxWidth = lines.map({ $0.union().maxX }).max() else { return [] }

    let offsetLines = lines.map { line in
        let width = line.union().maxX
        let diff = maxWidth - width

        var offset: CGFloat = .zero
        if horizontalAlignment == .center {
            offset = diff / 2
        }
        if horizontalAlignment == .trailing {
            offset = diff
        }

        return line.map { rect in
            CGRect(x: rect.minX + offset, y: rect.minY, width: rect.width, height: rect.height)
        }
    }

    return offsetLines.flatMap { $0 }
}

private extension [CGRect] {
    func union() -> CGRect {
        guard let first else { return .zero }
        return dropFirst().reduce(first) { $0.union($1) }
    }
}

@available(iOS 16.0, *)
public struct FlowLayout: Layout {

    public typealias Cache = [ViewDimensions]

    public func makeCache(subviews: Subviews) -> Cache {
        subviews.map { $0.dimensions(in: .unspecified) }
    }

    private let spacing: CGSize
    private let verticalAlignment: VerticalAlignment
    private let horizontalAlignment: HorizontalAlignment

    public init(
        spacing: CGSize = CGSize(width: 10, height: 10),
        verticalAlignment: VerticalAlignment = .top,
        horizontalAlignment: HorizontalAlignment = .leading
    ) {
        self.spacing = spacing
        self.verticalAlignment = verticalAlignment
        self.horizontalAlignment = horizontalAlignment
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout (Cache)
    ) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let sizes = cache
        return layout(
            sizes: sizes,
            spacing: spacing,
            containerWidth: width,
            verticalAlignment: verticalAlignment,
            horizontalAlignment: horizontalAlignment
        ).union().size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout (Cache)) {
        let sizes = cache
        let frames = layout(
            sizes: sizes,
            spacing: spacing,
            containerWidth: bounds.width,
            verticalAlignment: verticalAlignment,
            horizontalAlignment: horizontalAlignment
        )
        for (frame, subview) in zip(frames, subviews) {
            let position = CGPoint(x: frame.origin.x + bounds.minX, y: frame.origin.y + bounds.minY)
            subview.place(at: position, proposal: .unspecified)
        }
    }
}

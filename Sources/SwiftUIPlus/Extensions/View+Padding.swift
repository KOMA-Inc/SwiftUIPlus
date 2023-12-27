import SwiftUI

public struct Multipadding: ViewModifier {

    let edges: [Edge]

    public enum Edge {
        case leading(CGFloat)
        case trailing(CGFloat)
        case top(CGFloat)
        case bottom(CGFloat)
        case horizontal(CGFloat)
        case vertical(CGFloat)
        case all(CGFloat)
    }

    public func body(content: Content) -> some View {
        edges.reduce(AnyView(content)) { view, edge in
            AnyView(applyPadding(for: view, edge: edge))
        }
    }

    private func applyPadding<V>(for view: V, edge: Edge) -> some View where V: View {
        switch edge {
        case .leading(let value):
            view.padding(.leading, value)
        case .trailing(let value):
            view.padding(.trailing, value)
        case .top(let value):
            view.padding(.top, value)
        case .bottom(let value):
            view.padding(.bottom, value)
        case .horizontal(let value):
            view.padding(.horizontal, value)
        case .vertical(let value):
            view.padding(.vertical, value)
        case .all(let value):
            view.padding(.all, value)
        }
    }
}

public extension View {
    func padding(_ edges: Multipadding.Edge...) -> some View {
        modifier(Multipadding(edges: edges))
    }
}

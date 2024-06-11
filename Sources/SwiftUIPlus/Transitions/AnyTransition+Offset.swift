import SwiftUI

struct Offset: ViewModifier {

    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.offset(x: x, y: y)
    }
}

public extension AnyTransition {
    static func offset(x: CGFloat = .zero, y: CGFloat = .zero) -> Self {
        .modifier(active: Offset(x: x, y: y), identity: Offset(x: 0, y: 0))
    }
}

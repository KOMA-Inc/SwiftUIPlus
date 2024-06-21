import SwiftUI

public enum SwipeDirection {
    case up
    case left
    case right
    case down
}

public extension View {

    func onSwipe(
        _ direction: SwipeDirection...,
        perform action: @escaping () -> Void
    ) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                .onEnded { value in
                    switch(value.translation.width, value.translation.height) {
                    case (...0, -30...30):
                        if direction.contains(.left) {
                            action()
                        }
                    case (0..., -30...30):
                        if direction.contains(.right) {
                            action()
                        }
                    case (-100...100, ...0):
                        if direction.contains(.up) {
                            action()
                        }
                    case (-100...100, 0...):
                        if direction.contains(.down) {
                            action()
                        }
                    default:
                        break
                    }
                }
        )
    }
}

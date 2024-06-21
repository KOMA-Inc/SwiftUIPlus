import SwiftUI

public enum ToastLocation {
    case top
    case bottom

    var alignment: Alignment {
        switch self {
        case .top:
                .top
        case .bottom:
                .bottom
        }
    }

    var edge: Edge {
        switch self {
        case .top:
                .top
        case .bottom:
                .bottom
        }
    }

    var swipeDirection: SwipeDirection {
        switch self {
        case .top:
                .up
        case .bottom:
                .down
        }
    }
}

public extension View {

    func toast<Toast: View>(
        isPresented: Binding<Bool>,
        location: ToastLocation,
        @ViewBuilder toast: () -> Toast
    ) -> some View {
        ZStack(alignment: location.alignment) {
            self

            if isPresented.wrappedValue {
                toast()
                    .zIndex(1)
                    .transition(.move(edge: location.edge).combined(with: .opacity))
                    .onSwipe(location.swipeDirection) {
                        isPresented.wrappedValue = false
                    }

                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isPresented.wrappedValue = false
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented.wrappedValue)
    }
}

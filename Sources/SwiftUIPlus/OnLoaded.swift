import SwiftUI

struct OnLoadedView<Content: View>: View {

    let action: () -> Void
    let content: Content

    @State private var didCallAction = false

    public var body: some View {
        content
            .onAppear {
                if didCallAction { return }
                defer { didCallAction = true }
                action()
            }
    }
}

public extension View {

    func onLoad(_ action: @escaping () -> Void) -> some View {
        OnLoadedView(action: action, content: self)
    }
}

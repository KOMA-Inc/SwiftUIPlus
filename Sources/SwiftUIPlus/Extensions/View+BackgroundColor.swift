import SwiftUI

struct BackgroundColorKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

public extension EnvironmentValues {
    var backgroundColor: Color? {
        get { self[BackgroundColorKey.self] }
        set { self[BackgroundColorKey.self] = newValue }
    }
}

public extension View {
    /// Sets the environment value of the `\.backgroundColor` key path to the given background color value
    func backgroundColor(_ color: Color?) -> some View {
        environment(\.backgroundColor, color)
    }
}

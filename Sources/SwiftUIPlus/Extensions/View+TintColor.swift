import SwiftUI

struct TintColorKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

public extension EnvironmentValues {
    var tintColor: Color? {
        get { self[TintColorKey.self] }
        set { self[TintColorKey.self] = newValue }
    }
}

public extension View {
    /// Sets the environment value of the `\.tintColor` key path to the given tint color value
    func tintColor(_ color: Color?) -> some View {
        environment(\.tintColor, color)
    }
}

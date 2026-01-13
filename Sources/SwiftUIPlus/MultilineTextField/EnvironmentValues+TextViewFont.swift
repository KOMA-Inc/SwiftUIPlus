import SwiftUI

public extension EnvironmentValues {
    @Entry var textViewFont: UIFont?
}

public extension View {

    @available(*, deprecated, message: "Use .multilineTextViewStyle(_:) instead")
    func textViewFont(_ font: UIFont?) -> some  View {
        environment(\.textViewFont, font)
    }
}

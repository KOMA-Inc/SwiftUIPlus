import SwiftUI

public protocol MultilineTextViewStyle {

    func configure(_ textView: UITextView)
}

public struct DefaultMultilineTextViewStyle: MultilineTextViewStyle {
    public init() {}

    public func configure(_ textView: UITextView) {
    }
}

public extension EnvironmentValues {
    @Entry var multilineTextViewStyle: MultilineTextViewStyle = DefaultMultilineTextViewStyle()
}

public extension View {

    func multilineTextViewStyle(_ style: MultilineTextViewStyle) -> some View {
        environment(\.multilineTextViewStyle, style)
    }
}

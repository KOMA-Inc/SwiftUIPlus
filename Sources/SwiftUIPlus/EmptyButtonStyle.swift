import SwiftUI

public struct EmptyButtonStyle: PrimitiveButtonStyle {

    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onTapGesture {
                configuration.trigger()
            }
    }
}

public extension PrimitiveButtonStyle where Self == EmptyButtonStyle {

    /// A button style that doesn't style or decorate its content
    static var empty: EmptyButtonStyle { EmptyButtonStyle() }
}

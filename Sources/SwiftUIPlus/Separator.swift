import SwiftUI

public struct Separator: View {

    private var color: Color

    public init(color: Color = .gray) {
        self.color = color
    }

    public var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(color)
    }
}

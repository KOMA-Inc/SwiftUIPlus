import SwiftUI
import UIKit

public extension View {

    func font(_ font: UIFont) -> some View {
        self.font(Font(font))
    }
}

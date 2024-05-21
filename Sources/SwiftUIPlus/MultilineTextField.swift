import SwiftUI
import UIKit

fileprivate struct UITextViewWrapper: UIViewRepresentable {

    @Environment(\.textViewFont) private var textViewFont

    typealias UIViewType = UITextView

    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    var onDone: (() -> Void)?

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        if nil != onDone {
            textView.returnKeyType = .done
        }

        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return textView
    }

    func updateUIView(_ textView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
        textView.backgroundColor = UIColor.clear

        if let textViewFont {
            textView.font = textViewFont
        }

        if textView.text != text {
            textView.text = text
        }

        UITextViewWrapper.recalculateHeight(view: textView, result: $calculatedHeight)
    }

    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height // !! must be called asynchronously
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, height: $calculatedHeight, onDone: onDone)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var calculatedHeight: Binding<CGFloat>
        var onDone: (() -> Void)?

        init(text: Binding<String>, height: Binding<CGFloat>, onDone: (() -> Void)? = nil) {
            self.text = text
            self.calculatedHeight = height
            self.onDone = onDone
        }

        func textViewDidChange(_ uiView: UITextView) {
            text.wrappedValue = uiView.text
            UITextViewWrapper.recalculateHeight(view: uiView, result: calculatedHeight)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if let onDone = self.onDone, text == "\n" {
                textView.resignFirstResponder()
                onDone()
                return false
            }
            return true
        }
    }
}

public struct MultilineTextField: View {

    private var placeholder: String
    private var onCommit: (() -> Void)?

    @Binding private var text: String
    private var internalText: Binding<String> {
        Binding<String>(get: { text } ) {
            text = $0
            showingPlaceholder = $0.isEmpty
        }
    }

    @State private var dynamicHeight: CGFloat = 10
    @State private var showingPlaceholder = false

    public init(_ placeholder: String = "", text: Binding<String>, onCommit: (() -> Void)? = nil) {
        self.placeholder = placeholder
        self.onCommit = onCommit
        self._text = text
        self._showingPlaceholder = State<Bool>(initialValue: self.text.isEmpty)
    }

    public var body: some View {
        UITextViewWrapper(text: internalText, calculatedHeight: $dynamicHeight, onDone: onCommit)
            .frame(height: dynamicHeight)
            .overlay(placeholderView.allowsHitTesting(false), alignment: .topLeading)
    }

    private var placeholderView: some View {
        Group {
            if showingPlaceholder {
                Text(placeholder).foregroundColor(.gray)
                    .padding(.leading, 4)
                    .padding(.top, 8)
            }
        }
    }
}

struct TextViewFontKey: EnvironmentKey {
    static let defaultValue: UIFont? = nil
}

public extension EnvironmentValues {
    var textViewFont: UIFont? {
        get { self[TextViewFontKey.self] }
        set { self[TextViewFontKey.self] = newValue }
    }
}

public extension View {
    func textViewFont(_ font: UIFont?) -> some View {
        environment(\.textViewFont, font)
    }
}

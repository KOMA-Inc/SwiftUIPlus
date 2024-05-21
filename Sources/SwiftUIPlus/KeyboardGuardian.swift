import SwiftUI

public class KeyboardGuardian: ObservableObject {

    public var rects: [CGRect]

    @Published public var keyboardRect = CGRect()

    // keyboardWillShow notification may be posted repeatedly,
    // this flag makes sure we only act once per keyboard appearance
    private var keyboardIsHidden = true

    @Published public var slide: CGFloat = 0

    public var showField: Int = 0 {
        didSet {
            updateSlide()
        }
    }

    public init(textFieldCount: Int) {
        rects = .init(repeating: CGRect(), count: textFieldCount)
    }

    public func addObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyBoardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyBoardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // swiftlint:disable notification_center_detachment
    public func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    // swiftlint:enable notification_center_detachment

    deinit {
        removeObserver()
    }

    @objc
    private func keyBoardWillShow(notification: Notification) {
        if keyboardIsHidden {
            keyboardIsHidden = false
            if let rect = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect {
                keyboardRect = rect
                updateSlide()
            }
        }
    }

    @objc
    private func keyBoardWillHide(notification: Notification) {
        keyboardIsHidden = true
        keyboardRect = .zero
        updateSlide()
    }

    private func updateSlide() {
        if keyboardIsHidden {
            slide = 0
        } else {
            let tfRect = rects[showField]
            let diff = keyboardRect.minY - tfRect.maxY

            slide += diff > 0 ? diff : min(diff, 0)

        }
    }
}

public struct GeometryGetter: View {

    @Binding private var rect: CGRect

    public init(rect: Binding<CGRect>) {
        self._rect = rect
    }

    public var body: some View {
        GeometryReader { geometry in
            Group { () -> AnyView in
                DispatchQueue.main.async {
                    self.rect = geometry.frame(in: .global)
                }

                return AnyView(Color.clear)
            }
        }
    }
}

public struct ViewSizeKey<ID: Hashable>: PreferenceKey {

    public static var defaultValue: [ID: CGSize] { [:] }

    public static func reduce(value: inout [ID: CGSize], nextValue: () -> [ID: CGSize]) {
        value.merge(nextValue()) { $1 }
    }
}

public struct PropagateSize<V: View, ID: Hashable>: View {

    private let content: () -> V
    private let id: ID

    public init(_ id: ID, @ViewBuilder content: @escaping () -> V) {
        self.id = id
        self.content = content
    }

    public init(_ id: ID, content: V) {
        self.id = id
        self.content = { content }
    }

    public var body: some View {
        content()
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ViewSizeKey<ID>.self,
                        value: [id: proxy.size]
                    )
                },
                alignment: .center
            )
    }
}

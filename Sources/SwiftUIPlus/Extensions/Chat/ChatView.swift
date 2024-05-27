import SwiftUI

public struct ChatView<
    HeaderContent: View,
    MessageContent: View,
    InputViewContent: View,
    M: Message
>: View {

    public typealias HeaderViewBuilderClosure = () -> HeaderContent
    public typealias InputViewBuilderClosure = () -> InputViewContent
    public typealias MessageBuilderClosure = (M, Bool) -> MessageContent

    // MARK: - Injected

    private let messageBuilder: MessageBuilderClosure
    private let header: HeaderViewBuilderClosure
    private let inputView: InputViewBuilderClosure
    private let sections: [MessageSection<M>]

    var dateHeader: ((Date) -> AnyView)?
    var scrollToBottomView: (() -> AnyView)?

    public init(
        messages: [M],
        @ViewBuilder messageView: @escaping (M, Bool) -> MessageContent,
        @ViewBuilder header: @escaping () -> HeaderContent,
        @ViewBuilder inputView: @escaping () -> InputViewContent
    ) {
        self.sections = Self.mapMessages(messages)
        self.messageBuilder = messageView
        self.header = header
        self.inputView = inputView
    }

    @State private var isScrolledToBottom: Bool = true

    private var list: some View {
        UIList<MessageContent, M>(
            isScrolledToBottom: $isScrolledToBottom,
            messageBuilder: messageBuilder,
            dateHeader: dateHeader,
            sections: sections
        )
    }

    public var body: some View {
        VStack(spacing: .zero) {
            header()
            ZStack(alignment: .bottomTrailing) {
                list
                    .onTapGesture {
                        hideKeyboard()
                    }
                if !isScrolledToBottom, let scrollToBottomView {
                    Button {
                        NotificationCenter.default.post(name: .onScrollToBottom, object: nil)
                    } label: {
                        scrollToBottomView()
                    }
                }
            }
            inputView()
        }
    }
}

public extension ChatView {
    func dateHeader(@ViewBuilder content: @escaping (Date) -> some View) -> ChatView {
        var view = self
        view.dateHeader = { date in AnyView(content(date)) }
        return view
    }

    func scrollToBottomView(@ViewBuilder content: @escaping () -> some View) -> ChatView {
        var view = self
        view.scrollToBottomView = { AnyView(content()) }
        return view
    }
}

private extension ChatView {
    static func mapMessages(_ messages: [M]) -> [MessageSection<M>] {
        guard messages.hasUniqueIDs() else {
            fatalError("Messages can not have duplicate ids, please make sure every message gets a unique id")
        }
        let dates = Set(messages.map({ $0.createdAt.startOfDay() }))
            .sorted()
            .reversed()
        var result: [MessageSection<M>] = []

        for date in dates {
            let section = MessageSection<M>(
                messages: messages
                    .filter { $0.createdAt.isSameDay(date) }
                    .reversed(),
                date: date
            )
            result.append(section)
        }

        return result
    }
}

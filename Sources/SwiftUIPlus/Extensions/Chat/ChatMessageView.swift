import SwiftUI

struct ChatMessageView<Content: View, M: Message>: View {

    typealias MessageBuilderClosure = ChatView<EmptyView, Content, EmptyView, M>.MessageBuilderClosure

    private let message: M
    private let isLast: Bool
    private let messageBuilder: MessageBuilderClosure

    init(
        message: M,
        isLast: Bool,
        @ViewBuilder messageBuilder: @escaping MessageBuilderClosure
    ) {
        self.message = message
        self.isLast = isLast
        self.messageBuilder = messageBuilder
    }

    var body: some View {
        messageBuilder(message, isLast)
            .id(message.id)
    }
}

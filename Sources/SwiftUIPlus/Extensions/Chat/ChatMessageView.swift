import SwiftUI

struct ChatMessageView<Content: View, M: Message>: View {

    typealias MessageBuilderClosure = ChatView<EmptyView, Content, EmptyView, M>.MessageBuilderClosure

    private let message: M
    private let messageBuilder: MessageBuilderClosure

    init(message: M, @ViewBuilder messageBuilder: @escaping MessageBuilderClosure) {
        self.message = message
        self.messageBuilder = messageBuilder
    }

    var body: some View {
        messageBuilder(message)
            .id(message.id)
    }
}

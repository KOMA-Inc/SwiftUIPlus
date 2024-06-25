import SwiftUI

struct ChatMessageView<Content: View, M: Message>: View {

    private let id: M.ID
    private let content: Content

    init(
        message: M,
        content: Content
    ) {
        self.id = message.id
        self.content = content
    }

    var body: some View {
        content.id(id)
    }
}

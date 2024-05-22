public struct MessageSection<M: Message> {
    var messages: [M]
    let date: Date
}

extension MessageSection: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.messages == rhs.messages &&
        lhs.date == rhs.date
    }
}

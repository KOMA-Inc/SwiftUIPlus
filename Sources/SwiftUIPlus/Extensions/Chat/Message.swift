public protocol Message: Equatable, Identifiable {
    var id: String { get }
    var createdAt: Date { get }
}

extension Array where Element: Identifiable {
    func hasUniqueIDs() -> Bool {
        var uniqueElements: [Element.ID] = []
        for el in self {
            if !uniqueElements.contains(el.id) {
                uniqueElements.append(el.id)
            } else {
                return false
            }
        }
        return true
    }
}

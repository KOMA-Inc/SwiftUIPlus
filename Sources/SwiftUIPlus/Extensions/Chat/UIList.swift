import SwiftUI

struct UIList<MessageContent: View, M: Message>: UIViewRepresentable {

    typealias Section = MessageSection<M>

    typealias MessageBuilderClosure = ChatView<EmptyView, MessageContent, EmptyView, M>.MessageBuilderClosure

    @Binding var isScrolledToBottom: Bool
    let messageBuilder: MessageBuilderClosure
    let dateHeader: ((Date) -> AnyView)?
    let sections: [Section]

    @State private var isScrolledToTop = false

    private let updatesQueue = DispatchQueue(label: "updatesQueue", qos: .utility)
    @State private var updateSemaphore = DispatchSemaphore(value: 1)
    @State private var tableSemaphore = DispatchSemaphore(value: 0)

    func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.transform = CGAffineTransform(rotationAngle: .pi)

        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedSectionHeaderHeight = 1
        tableView.estimatedSectionFooterHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.scrollsToTop = false

        NotificationCenter.default.addObserver(forName: .onScrollToBottom, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                if !context.coordinator.sections.isEmpty {
                    tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
                }
            }
        }

        return tableView
    }

    func maxContentOffset(scrollView: UIScrollView) -> CGPoint {
        return CGPoint(
            x: scrollView.contentSize.width - scrollView.bounds.width + scrollView.contentInset.right,
            y: scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
    }

    func updateUIView(_ tableView: UITableView, context: Context) {
        if context.coordinator.sections == sections {
            return
        }
        updatesQueue.async {
            updateSemaphore.wait()

            if context.coordinator.sections == sections {
                updateSemaphore.signal()
                return
            }

            let prevSections = context.coordinator.sections

            // step 1 - prepare intermediate sections and operations
            let (
                appliedDeletes,
                appliedDeletesSwapsAndEdits,
                deleteOperations,
                swapOperations,
                editOperations,
                insertOperations
            ) = operationsSplit(
                oldSections: prevSections,
                newSections: sections
            )

            DispatchQueue.main.async {
                tableView.performBatchUpdates {
                    // Step 2 - delete sections and rows if necessary
                    context.coordinator.sections = appliedDeletes
                    for operation in deleteOperations {
                        applyOperation(operation, tableView: tableView)
                    }
                } completion: { _ in
                    tableSemaphore.signal()
                }
            }
            tableSemaphore.wait()

            DispatchQueue.main.async {
                tableView.performBatchUpdates {
                    // Step 3 - swap places for rows that moved inside the table
                    // (example of how this happens. send two messages: first m1, then m2.
                    // if m2 is delivered to server faster, then it should jump
                    // above m1 even though it was sent later)
                    context.coordinator.sections = appliedDeletesSwapsAndEdits // NOTE: this array already contains necessary edits, but won't be a problem for applying swaps
                    for operation in swapOperations {
                        applyOperation(operation, tableView: tableView)
                    }
                } completion: { _ in
                    tableSemaphore.signal()
                }
            }
            tableSemaphore.wait()

            DispatchQueue.main.async {
                tableView.performBatchUpdates {
                    // Step 4 - check only sections that are already in the table
                    // for existing rows that changed and apply only them to
                    // table's dataSource without animation
                    context.coordinator.sections = appliedDeletesSwapsAndEdits
                    for operation in editOperations {
                        applyOperation(operation, tableView: tableView)
                    }
                } completion: { _ in
                    tableSemaphore.signal()
                }
            }
            tableSemaphore.wait()

            if isScrolledToBottom || isScrolledToTop {
                DispatchQueue.main.sync {
                    // Step 5 - apply the rest of the changes to table's dataSource, i.e. inserts
                    context.coordinator.sections = sections

                    tableView.beginUpdates()
                    for operation in insertOperations {
                        applyOperation(operation, tableView: tableView)
                    }
                    tableView.endUpdates()

                    updateSemaphore.signal()
                }
            } else {
                updateSemaphore.signal()
            }
        }
    }

    // MARK: - Operations

    enum Operation {
        case deleteSection(Int)
        case insertSection(Int)

        case delete(Int, Int) // delete with animation
        case insert(Int, Int) // insert with animation
        case swap(Int, Int, Int) // delete first with animation, then insert it into new position with animation. do not do anything with the second for now
        case edit(Int, Int) // reload the element without animation
    }

    func applyOperation(_ operation: Operation, tableView: UITableView) {
        switch operation {
        case .deleteSection(let section):
            tableView.deleteSections([section], with: .top)
        case .insertSection(let section):
            tableView.insertSections([section], with: .top)

        case .delete(let section, let row):
            tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: .top)
        case .insert(let section, let row):
            tableView.insertRows(at: [IndexPath(row: row, section: section)], with: .top)
        case .edit(let section, let row):
            tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .none)
        case .swap(let section, let rowFrom, let rowTo):
            tableView.deleteRows(at: [IndexPath(row: rowFrom, section: section)], with: .top)
            tableView.insertRows(at: [IndexPath(row: rowTo, section: section)], with: .top)
        }
    }

    func operationsSplit(
        oldSections: [Section],
        newSections: [Section]
    ) -> (
        [Section],
        [Section],
        [Operation],
        [Operation],
        [Operation],
        [Operation]
    ) {
        var appliedDeletes = oldSections // start with old sections, remove rows that need to be deleted
        var appliedDeletesSwapsAndEdits = newSections // take new sections and remove rows that need to be inserted for now, then we'll get array with all the changes except for inserts
        // appliedDeletesSwapsEditsAndInserts == newSection

        var deleteOperations = [Operation]()
        var swapOperations = [Operation]()
        var editOperations = [Operation]()
        var insertOperations = [Operation]()

        // 1 compare sections

        let oldDates = oldSections.map { $0.date }
        let newDates = newSections.map { $0.date }
        let commonDates = Array(Set(oldDates + newDates)).sorted(by: >)
        for date in commonDates {
            let oldIndex = appliedDeletes.firstIndex(where: { $0.date == date } )
            let newIndex = appliedDeletesSwapsAndEdits.firstIndex(where: { $0.date == date } )
            if oldIndex == nil, let newIndex {
                // operationIndex is not the same as newIndex because appliedDeletesSwapsAndEdits is being changed as we go, but to apply changes to UITableView we should have initial index
                if let operationIndex = newSections.firstIndex(where: { $0.date == date } ) {
                    appliedDeletesSwapsAndEdits.remove(at: newIndex)
                    insertOperations.append(.insertSection(operationIndex))
                }
                continue
            }
            if newIndex == nil, let oldIndex {
                if let operationIndex = oldSections.firstIndex(where: { $0.date == date } ) {
                    appliedDeletes.remove(at: oldIndex)
                    deleteOperations.append(.deleteSection(operationIndex))
                }
                continue
            }
            guard let newIndex, let oldIndex else { continue }

            // 2 compare section rows
            // isolate deletes and inserts, and remove them from row arrays, leaving only rows that are in both arrays: 'duplicates'
            // this will allow to compare relative position changes of rows - swaps

            var oldRows = appliedDeletes[oldIndex].messages
            var newRows = appliedDeletesSwapsAndEdits[newIndex].messages
            let oldRowIDs = Set(oldRows.map { $0.id })
            let newRowIDs = Set(newRows.map { $0.id })
            let rowIDsToDelete = oldRowIDs.subtracting(newRowIDs)
            let rowIDsToInsert = newRowIDs.subtracting(oldRowIDs) // TODO is order important?
            for rowId in rowIDsToDelete {
                if let index = oldRows.firstIndex(where: { $0.id == rowId }) {
                    oldRows.remove(at: index)
                    deleteOperations.append(.delete(oldIndex, index)) // this row was in old section, should not be in final result
                }
            }
            for rowId in rowIDsToInsert {
                if let index = newRows.firstIndex(where: { $0.id == rowId }) {
                    // this row was not in old section, should add it to final result
                    insertOperations.append(.insert(newIndex, index))
                }
            }

            for rowId in rowIDsToInsert {
                if let index = newRows.firstIndex(where: { $0.id == rowId }) {
                    // remove for now, leaving only 'duplicates'
                    newRows.remove(at: index)
                }
            }

            // 3 isolate swaps and edits

            for i in 0..<oldRows.count {
                let oldRow = oldRows[i]
                let newRow = newRows[i]
                if oldRow.id != newRow.id { // a swap: rows in same position are not actually the same rows
                    if let index = newRows.firstIndex(where: { $0.id == oldRow.id }) {
                        if !swapsContain(swaps: swapOperations, section: oldIndex, index: i) ||
                            !swapsContain(swaps: swapOperations, section: oldIndex, index: index) {
                            swapOperations.append(.swap(oldIndex, i, index))
                        }
                    }
                } else if oldRow != newRow { // same ids om same positions but something changed - reload rows without animation
                    editOperations.append(.edit(oldIndex, i))
                }
            }

            // 4 store row changes in sections

            appliedDeletes[oldIndex].messages = oldRows
            appliedDeletesSwapsAndEdits[newIndex].messages = newRows
        }

        return (appliedDeletes, appliedDeletesSwapsAndEdits, deleteOperations, swapOperations, editOperations, insertOperations)
    }

    func swapsContain(swaps: [Operation], section: Int, index: Int) -> Bool {
        swaps.filter {
            if case let .swap(section, rowFrom, rowTo) = $0 {
                return section == section && (rowFrom == index || rowTo == index)
            }
            return false
        }.count > 0
    }

    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isScrolledToBottom: $isScrolledToBottom,
            isScrolledToTop: $isScrolledToTop,
            messageBuilder: messageBuilder,
            dateHeader: dateHeader,
            sections: sections
        )
    }

    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {

        @Binding var isScrolledToBottom: Bool
        @Binding var isScrolledToTop: Bool

        private let messageBuilder: MessageBuilderClosure
        let dateHeader: ((Date) -> AnyView)?
        var sections: [Section]

        init(
            isScrolledToBottom: Binding<Bool>,
            isScrolledToTop: Binding<Bool>,
            messageBuilder: @escaping MessageBuilderClosure,
            dateHeader: ((Date) -> AnyView)?,
            sections: [Section]
        ) {
            self._isScrolledToBottom = isScrolledToBottom
            self._isScrolledToTop = isScrolledToTop
            self.messageBuilder = messageBuilder
            self.dateHeader = dateHeader
            self.sections = sections
        }

        func numberOfSections(in tableView: UITableView) -> Int {
            sections.count
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            sections[section].messages.count
        }

        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            nil
        }

        func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
            if let dateHeader {
                let view = UIHostingController(
                    rootView: dateHeader(sections[section].date)
                        .rotationEffect(Angle(degrees: 180))
                ).view
                view?.backgroundColor = .clear
                return view
            } else {
                return nil
            }
        }

        func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            0.1
        }

        func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            if dateHeader == nil {
                .zero
            } else {
                UITableView.automaticDimension
            }
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as? ChatMessageCell else {
                return .init()
            }

            cell.selectionStyle = .none
            cell.backgroundColor = .clear

            let message = sections[indexPath.section].messages[indexPath.row]

            let view = ChatMessageView(message: message, messageBuilder: messageBuilder)
                .rotationEffect(Angle(degrees: 180))
            cell.configure(view: view)

            return cell
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            isScrolledToBottom = scrollView.contentOffset.y <= 50
            isScrolledToTop = scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.height - 1
        }
    }
}


private class ChatMessageCell: UITableViewCell {
    private var hostingController: UIHostingController<AnyView>?

    func configure<Content: View>(view: Content) {
        // Remove previous hosting controller if exists
        hostingController?.view.removeFromSuperview()

        let hostingController = UIHostingController(rootView: AnyView(view))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        contentView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        self.hostingController = hostingController
    }
}

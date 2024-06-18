import SwiftUI

public struct AutoScrollingTableView<Content: View>: UIViewRepresentable {
    let scrollSpeed: CGFloat
    let uniqueElements: Int
    let viewBuilder: (Int) -> Content

    public init(scrollSpeed: CGFloat, uniqueElements: Int, @ViewBuilder viewBuilder: @escaping (Int) -> Content) {
        self.scrollSpeed = scrollSpeed
        self.uniqueElements = uniqueElements
        self.viewBuilder = viewBuilder
    }

    public func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        context.coordinator.scrollToCenter(of: tableView)
        context.coordinator.startAutoScrolling()
        return tableView
    }

    public func updateUIView(_ uiView: UITableView, context: Context) {

    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
        var parent: AutoScrollingTableView
        var displayLink: CADisplayLink?
        weak var tableView: UITableView?

        init(_ parent: AutoScrollingTableView) {
            self.parent = parent
        }

        func scrollToCenter(of tableView: UITableView) {
            self.tableView = tableView
            let total = 10_000
            let unique = parent.uniqueElements
            let repeats = total / unique
            let middleOccurrence = repeats / 2
            let middleIndex = middleOccurrence * unique
            guard middleIndex < total else {
                return
            }

            DispatchQueue.main.async {
                tableView.scrollToRow(at: IndexPath(row: middleIndex, section: 0), at: .top, animated: false)
            }
        }

        func startAutoScrolling() {
            displayLink = CADisplayLink(target: self, selector: #selector(scroll))
            displayLink?.add(to: .main, forMode: .default)
        }

        func stopAutoScrolling() {
            displayLink?.invalidate()
            displayLink = nil
        }

        @objc func scroll() {
            guard let tableView else { return }

            var newOffset = tableView.contentOffset
            newOffset.y += parent.scrollSpeed

            // Reset the content offset to the top if it reaches the bottom
            if newOffset.y >= tableView.contentSize.height - tableView.frame.size.height {
                newOffset.y = 0
            }

            tableView.contentOffset = newOffset
        }

        public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            10_000
        }

        public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let row = indexPath.row % parent.uniqueElements
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let hostingController = UIHostingController(rootView: parent.viewBuilder(row))
            hostingController.view.backgroundColor = .clear
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.contentView.addSubview(hostingController.view)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none

            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
            ])

            return cell
        }

        public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            stopAutoScrolling()
        }

        public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            startAutoScrolling()
        }

        deinit {
            stopAutoScrolling()
        }
    }
}

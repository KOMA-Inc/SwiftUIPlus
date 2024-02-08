import LazyPager
import SwiftUI

public struct ImagesPreview<DataCollection: RandomAccessCollection, Content: View, Header: View>: View where DataCollection.Index == Int {

    private let data: DataCollection
    private let index: Binding<Int>
    private let content: (DataCollection.Element) -> Content
    private let header: (() -> Header)?

    var tapAction: (() -> Void)?
    var hideInterfaceOnTap = true

    public init(
        data: DataCollection,
        index: Binding<Int>,
        @ViewBuilder content: @escaping (DataCollection.Element) -> Content,
        @ViewBuilder header: @escaping (() -> Header)
    ) {
        self.data = data
        self.index = index
        self.content = content
        self.header = header
    }

    public func onTap(hideInterface: Bool = true, action: (() -> Void)? = nil) -> Self {
        var this = self
        this.hideInterfaceOnTap = hideInterface
        this.tapAction = action
        return this
    }

    @State private var showInterface = true

    public var body: some View {
        ZStack {
            LazyPager(data: data, page: index) { element in
                content(element)
            }
            .zoomable(min: 1, max: 5)
            .onTap {
                withAnimation {
                    tapAction?()
                    if hideInterfaceOnTap {
                        showInterface.toggle()
                    }
                }
            }
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity)

            Group {
                if let header {
                    VStack {
                        header()
                        Spacer()
                    }
                }

                if data.count > 1 {
                    VStack {
                        Spacer()
                        PageControl(numberOfPages: data.count, currentPage: index)
                    }
                }

            }
            .opacity(showInterface ? 1 : 0)
        }
    }
}

public extension ImagesPreview where Header == EmptyView {
    init(
        data: DataCollection,
        index: Binding<Int>,
        @ViewBuilder content: @escaping (DataCollection.Element) -> Content
    ) {
        self.data = data
        self.index = index
        self.content = content
        self.header = nil
    }
}

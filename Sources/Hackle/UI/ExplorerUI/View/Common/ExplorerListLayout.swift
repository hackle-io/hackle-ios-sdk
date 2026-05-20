import SwiftUI

struct ExplorerScrollList<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if #available(iOS 14.0, *) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    content()
                }
            }
        } else {
            List {
                content()
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(PlainListStyle())
        }
    }
}

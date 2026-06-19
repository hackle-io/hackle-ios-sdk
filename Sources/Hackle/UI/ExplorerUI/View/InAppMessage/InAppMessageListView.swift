import SwiftUI

struct InAppMessageListView: View {

    @ObservedObject var viewModel: ExplorerViewModel

    var body: some View {
        VStack(spacing: 0) {
            ExplorerScrollList {
                ForEach(viewModel.inAppMessageItems, id: \.inAppMessage.id) { item in
                    InAppMessageRowView(
                        keyLabel: item.keyLabel,
                        descLabel: item.descLabel,
                        reasonLabel: item.reasonLabel,
                        isEligible: item.isEligible,
                        isTappable: item.isTappable,
                        onTap: { viewModel.loadInAppMessageDetail(item: item) }
                    )
                    Divider()
                }
            }
        }
        .background(Color.white)
        .onAppear {
            viewModel.loadInAppMessages()
        }
        .sheet(item: $viewModel.detailPresentation) { presentation in
            InAppMessageDetailSheetView(presentation: presentation)
        }
    }
}

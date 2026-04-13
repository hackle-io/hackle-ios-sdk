import SwiftUI

struct UserInfoSectionView: View {

    @ObservedObject var viewModel: ExplorerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            infoRow(title: "ID", value: viewModel.defaultId)
            infoRow(title: "DEVICE ID", value: viewModel.deviceId)
            infoRow(title: "USER ID", value: viewModel.userId)
            infoRow(title: "PUSH TOKEN", value: viewModel.pushToken)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
    }

    private func infoRow(title: String, value: String?) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                Text(value ?? "N/A")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.627, green: 0.627, blue: 0.627))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            Button("Copy") {
                if let value = value {
                    viewModel.copyToClipboard(value)
                }
            }
            .font(.system(size: 15))
            .disabled(value == nil)
            .frame(width: 60, height: 25)
        }
    }
}

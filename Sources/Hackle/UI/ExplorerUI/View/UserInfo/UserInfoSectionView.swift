import SwiftUI

struct UserInfoSectionView: View {

    @ObservedObject var viewModel: ExplorerViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Identifiers")
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
            VStack(alignment: .leading, spacing: 8) {
                identifierRow(title: "ID", value: viewModel.defaultId)
                identifierRow(title: "DEVICE ID", value: viewModel.deviceId)
                identifierRow(title: "USER ID", value: viewModel.userId)
                identifierRow(title: "PUSH TOKEN", value: viewModel.pushToken)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            Spacer()
                .frame(height: 12)
            HStack {
                Text("Properties")
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                .frame(alignment: .leading)
            ExplorerScrollList {
                ForEach(viewModel.properties, id: \.id) {
                    propertiesRow(property: $0)
                        .padding(.horizontal, 12)
                        .frame(height: 65)
                        .background(Color.white)
                    Divider()
                }
            }
        }
        .background(Color.white)
    }

    private func identifierRow(title: String, value: String?) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                Text(value ?? "N/A")
                    .font(.system(size: 14))
                    .foregroundColor(Color.explorerSecondaryText)
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
    
    private func propertiesRow(property: ExplorerUserProperty) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(property.key)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                Text(property.stringValue())
                    .font(.system(size: 14))
                    .foregroundColor(Color.explorerSecondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            Button("Copy") {
                viewModel.copyToClipboard(property.stringValue())
            }
            .font(.system(size: 15))
            .frame(width: 60, height: 25)
        }
    }
}

fileprivate extension ExplorerUserProperty {
    func stringValue() -> String {
        if let stringValue = self.value as? String {
            stringValue
        } else if let intValue = self.value as? NSNumber {
            "\(intValue)"
        } else {
            "\(String(describing: self.value))"
        }
    }
}

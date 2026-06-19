import SwiftUI

struct UserInfoSectionView: View {

    @ObservedObject var viewModel: ExplorerViewModel

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader("IDENTIFIERS")
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                identifierRow(title: "ID", value: viewModel.defaultId)
                Divider()
                identifierRow(title: "DEVICE ID", value: viewModel.deviceId)
                Divider()
                identifierRow(title: "USER ID", value: viewModel.userId)
                Divider()
                identifierRow(title: "PUSH TOKEN", value: viewModel.pushToken)
            }
            .padding(.horizontal, 12)
            .background(Color.white)
            Spacer()
                .frame(height: 12)
            sectionHeader("PROPERTIES")
            Divider()
            ExplorerScrollList {
                ForEach(viewModel.properties, id: \.id) {
                    propertiesRow(property: $0)
                        .padding(.horizontal, 12)
                        .frame(height: 56)
                        .background(Color.white)
                    Divider()
                }
            }
        }
        .background(Color.white)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.explorerSecondaryText)
            Spacer()
        }
        .frame(height: 36)
        .padding(.horizontal, 12)
    }

    private func identifierRow(title: String, value: String?) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.88))
                Text(value ?? "N/A")
                    .font(.system(size: 13))
                    .foregroundColor(Color.explorerSecondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            ExplorerCopyButton(isEnabled: value != nil) {
                if let value = value {
                    viewModel.copyToClipboard(value)
                }
            }
        }
        .frame(height: 56)
    }
    
    private func propertiesRow(property: ExplorerUserProperty) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(property.key)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.88))
                Text(property.stringValue())
                    .font(.system(size: 13))
                    .foregroundColor(Color.explorerSecondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            ExplorerCopyButton {
                viewModel.copyToClipboard(property.stringValue())
            }
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

#Preview {
    UserInfoSectionView(viewModel: ExplorerViewModel(explorer: MockUserExplorer()))
}

import SwiftUI

struct InAppMessageRowView: View {

    let keyLabel: String
    let descLabel: String
    let reasonLabel: String
    let isEligible: Bool
    let isTappable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: { if isTappable { onTap() } }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(keyLabel)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.88))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(descLabel)
                        .font(.system(size: 13))
                        .foregroundColor(Color.explorerSecondaryText)
                        .lineLimit(1)
                }
                Spacer()
                Text(reasonLabel)
                    .font(.system(size: 13))
                    .foregroundColor(isEligible ? .blue : Color.explorerSecondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if isTappable {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.explorerSecondaryText)
                        .padding(.leading, 2)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isTappable)
    }
}

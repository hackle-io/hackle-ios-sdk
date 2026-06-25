import SwiftUI

struct InAppMessageRowView: View {

    let keyLabel: String
    let descLabel: String
    let reasonLabel: String
    let isEligible: Bool

    var body: some View {
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
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(Color.white)
    }
}

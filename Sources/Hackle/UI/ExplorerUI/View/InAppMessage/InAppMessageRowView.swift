import SwiftUI

struct InAppMessageRowView: View {

    let keyLabel: String
    let descLabel: String
    let reasonLabel: String
    let isEligible: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(keyLabel)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(descLabel)
                    .font(.system(size: 12))
                    .foregroundColor(Color.explorerSecondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Text(reasonLabel)
                .font(.system(size: 12))
                .foregroundColor(isEligible ? .blue : Color.explorerSecondaryText)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 12)
        .frame(height: 65)
        .background(Color.white)
    }
}

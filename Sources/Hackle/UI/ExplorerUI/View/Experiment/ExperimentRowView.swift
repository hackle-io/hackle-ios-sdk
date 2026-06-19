import SwiftUI

struct ExperimentRowView: View {

    let keyLabel: String
    let descLabel: String
    let variationTitle: String
    let isOverridable: Bool
    let isResetEnabled: Bool
    let variations: [ActionSheetVariation]
    let onOverrideSet: (ActionSheetVariation) -> Void
    let onOverrideReset: () -> Void

    @State private var showActionSheet = false

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
            Button(variationTitle) {
                showActionSheet = true
            }
            .font(.system(size: 13))
            .disabled(!isOverridable)
            .frame(width: 60, height: 25)
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text(""),
                    buttons: variations.map { variation in
                        .default(Text(variation.title)) {
                            onOverrideSet(variation)
                        }
                    } + [
                        .destructive(Text("Reset")) { onOverrideReset() },
                        .cancel(Text("Cancel"))
                    ]
                )
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(Color.white)
    }
}

struct ActionSheetVariation {
    let title: String
    let variation: Variation
}

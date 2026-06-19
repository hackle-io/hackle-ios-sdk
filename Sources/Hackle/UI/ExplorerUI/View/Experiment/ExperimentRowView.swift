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
            Button(action: {
                showActionSheet = true
            }) {
                if isResetEnabled {
                    Text(variationTitle)
                    + Text("*")
                        .font(.system(size: 12))
                        .baselineOffset(4)
                } else {
                    Text(variationTitle)
                }
            }
            .font(.system(size: 14, weight: isResetEnabled ? .bold : .regular))
            .disabled(!isOverridable)
            .frame(width: 60, height: 25)
            .actionSheet(isPresented: $showActionSheet) {
                var actionButtons: [ActionSheet.Button] = variations.map { variation in
                    .default(Text(variation.title)) {
                        onOverrideSet(variation)
                    }
                }

                if isResetEnabled {
                    actionButtons.append(.destructive(Text("Reset")) { onOverrideReset() })
                }

                actionButtons.append(.cancel(Text("Cancel")))
                
                return ActionSheet(
                    title: Text(""),
                    buttons: actionButtons
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

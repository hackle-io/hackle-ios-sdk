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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(keyLabel)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(descLabel)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.627, green: 0.627, blue: 0.627))
                    .lineLimit(1)
            }
            Spacer()
            Button(variationTitle) {
                showActionSheet = true
            }
            .font(.system(size: 15))
            .disabled(!isOverridable)
            .frame(width: 60, height: 25)
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text(""),
                    buttons: variations.map { variation in
                        .default(Text(variation.title)) {
                            onOverrideSet(variation)
                        }
                    } + [.cancel(Text("Cancel"))]
                )
            }
            Button("Reset") {
                onOverrideReset()
            }
            .font(.system(size: 15))
            .disabled(!isResetEnabled)
            .frame(width: 60, height: 25)
        }
        .padding(.horizontal, 12)
        .frame(height: 65)
        .background(Color.white)
    }
}

struct ActionSheetVariation {
    let title: String
    let variation: Variation
}

import SwiftUI

struct FeatureFlagListView: View {

    @ObservedObject var viewModel: ExplorerViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Reset all") {
                    viewModel.resetAllFeatureFlagOverrides()
                }
                .font(.system(size: 15))
                .frame(width: 60, height: 25)
                .padding(.trailing, 12)
            }
            .frame(height: 40)
            .background(Color.white)

            ExplorerScrollList {
                ForEach(viewModel.featureFlagItems, id: \.experiment.id) { item in
                    ExperimentRowView(
                        keyLabel: item.keyLabel,
                        descLabel: item.descLabel,
                        variationTitle: String(item.decision.isOn),
                        isOverridable: DecisionReasons.isOverridable(reason: item.decision.reason),
                        isResetEnabled: item.overriddenVariation != nil,
                        variations: item.experiment.variations.map { variation in
                            ActionSheetVariation(title: String(variation.isOn), variation: variation)
                        },
                        onOverrideSet: { selected in
                            viewModel.setFeatureFlagOverride(experiment: item.experiment, variation: selected.variation)
                        },
                        onOverrideReset: {
                            if let variation = currentVariation(for: item) {
                                viewModel.resetFeatureFlagOverride(experiment: item.experiment, variation: variation)
                            }
                        }
                    )
                    Divider()
                }
            }
        }
        .background(Color.white)
        .onAppear {
            viewModel.loadFeatureFlags()
        }
    }

    private func currentVariation(for item: HackleFeatureFlagItem) -> Variation? {
        let isOn = item.decision.isOn
        return item.experiment.variations.first { $0.isOn == isOn }
    }
}

private extension HackleFeatureFlagItem {
    var keyLabel: String {
        "[\(experiment.key)] \(experiment.name ?? "")"
    }

    var descLabel: String {
        "\(experiment.status.rawValue) | \(experiment.identifierType)"
    }
}

private extension Variation {
    var isOn: Bool {
        key != "A"
    }
}

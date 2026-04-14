import SwiftUI

struct AbTestListView: View {

    @ObservedObject var viewModel: ExplorerViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Reset all") {
                    viewModel.resetAllAbTestOverrides()
                }
                .font(.system(size: 15))
                .frame(width: 60, height: 25)
                .padding(.trailing, 12)
            }
            .frame(height: 40)
            .background(Color.white)

            ExplorerScrollList {
                ForEach(viewModel.abTestItems, id: \.experiment.id) { item in
                    ExperimentRowView(
                        keyLabel: item.keyLabel,
                        descLabel: item.descLabel,
                        variationTitle: item.decision.variation,
                        isOverridable: DecisionReasons.isOverridable(reason: item.decision.reason),
                        isResetEnabled: item.overriddenVariation != nil,
                        variations: item.experiment.variations.map { variation in
                            ActionSheetVariation(title: variation.key, variation: variation)
                        },
                        onOverrideSet: { selected in
                            viewModel.setAbTestOverride(experiment: item.experiment, variation: selected.variation)
                        },
                        onOverrideReset: {
                            if let variation = currentVariation(for: item) {
                                viewModel.resetAbTestOverride(experiment: item.experiment, variation: variation)
                            }
                        }
                    )
                    Divider()
                }
            }
        }
        .background(Color.white)
        .onAppear {
            viewModel.loadAbTests()
        }
    }

    private func currentVariation(for item: HackleAbTestItem) -> Variation? {
        item.experiment.getVariationOrNil(variationKey: item.decision.variation)
    }
}

private extension HackleAbTestItem {
    var keyLabel: String {
        "[\(experiment.key)] \(experiment.name ?? "")"
    }

    var descLabel: String {
        [
            "V\(experiment.version)",
            experiment.status.rawValue,
            experiment.variations.map(\.key)
                .joined(separator: "/"),
            experiment.identifierType
        ]
            .joined(separator: " | ")
    }
}

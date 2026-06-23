import Foundation
import SwiftUI

@MainActor
class ExplorerViewModel: ObservableObject {

    private let explorer: HackleUserExplorer

    @Published var defaultId: String?
    @Published var deviceId: String?
    @Published var userId: String?
    @Published var pushToken: String?
    @Published var properties: [ExplorerUserProperty] = []

    @Published var selectedTab: ExplorerTab = .user

    @Published var abTestItems: [HackleAbTestItem] = []
    @Published var featureFlagItems: [HackleFeatureFlagItem] = []
    @Published var inAppMessageItems: [HackleInAppMessageItem] = []
    @Published var detailPresentation: InAppMessageDetailPresentation?

    init(explorer: HackleUserExplorer) {
        self.explorer = explorer
    }

    func loadUser() {
        let user = explorer.currentUser()
        defaultId = user.id
        deviceId = user.deviceId
        userId = user.userId
        properties = user.properties.enumerated()
            .map { index, element in
                ExplorerUserProperty(
                    id: Int64(index),
                    key: element.key,
                    value: element.value
                )
            }
        pushToken = explorer.registeredPushToken()
    }

    func loadAbTests() {
        let decisions = explorer.getAbTestDecisions()
        let overrides = explorer.getAbTestOverrides()
        abTestItems = HackleAbTestItem.of(decisions: decisions, overrides: overrides)
    }

    func loadFeatureFlags() {
        let decisions = explorer.getFeatureFlagDecisions()
        let overrides = explorer.getFeatureFlagOverrides()
        featureFlagItems = HackleFeatureFlagItem.of(decisions: decisions, overrides: overrides)
    }

    func loadInAppMessages() {
        let decisions = explorer.getInAppMessageDecisions()
        inAppMessageItems = HackleInAppMessageItem.of(decisions: decisions)
    }

    func loadInAppMessageDetail(item: HackleInAppMessageItem) {
        guard item.isTappable,
              let detail = explorer.getInAppMessageDebugInfo(inAppMessage: item.inAppMessage, reason: item.evaluation.reason)
        else {
            return
        }
        detailPresentation = InAppMessageDetailPresentation(
            id: item.inAppMessage.id,
            keyLabel: item.keyLabel,
            reason: item.reasonLabel,
            isEligible: item.isEligible,
            detail: detail
        )
    }

    func setAbTestOverride(experiment: Experiment, variation: Variation) {
        explorer.setAbTestOverride(experiment: experiment, variation: variation)
        loadAbTests()
    }

    func resetAbTestOverride(experiment: Experiment, variation: Variation) {
        explorer.resetAbTestOverride(experiment: experiment, variation: variation)
        loadAbTests()
    }

    func resetAllAbTestOverrides() {
        explorer.resetAllAbTestOverride()
        loadAbTests()
    }

    func setFeatureFlagOverride(experiment: Experiment, variation: Variation) {
        explorer.setFeatureFlagOverride(experiment: experiment, variation: variation)
        loadFeatureFlags()
    }

    func resetFeatureFlagOverride(experiment: Experiment, variation: Variation) {
        explorer.resetFeatureFlagOverride(experiment: experiment, variation: variation)
        loadFeatureFlags()
    }

    func resetAllFeatureFlagOverrides() {
        explorer.resetAllFeatureFlagOverride()
        loadFeatureFlags()
    }

    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        Metrics.counter(name: "user.explorer.identifier.copy").increment()
    }
}

struct InAppMessageDetailPresentation: Identifiable {
    let id: Int64
    let keyLabel: String
    let reason: String
    let isEligible: Bool
    let detail: InAppMessageDetail
}

struct ExplorerUserProperty: Identifiable {
    let id: Int64
    let key: String
    let value: Any
}

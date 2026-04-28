import Foundation
import SwiftUI

@MainActor
class ExplorerViewModel: ObservableObject {

    private let explorer: HackleUserExplorer

    @Published var defaultId: String?
    @Published var deviceId: String?
    @Published var userId: String?
    @Published var pushToken: String?
    @Published var showCopiedToast: Bool = false
    private var toastTask: Task<Void, Never>?

    @Published var selectedTab: ExplorerTab = .abTest

    @Published var abTestItems: [HackleAbTestItem] = []
    @Published var featureFlagItems: [HackleFeatureFlagItem] = []
    @Published var inAppMessageItems: [HackleInAppMessageItem] = []

    init(explorer: HackleUserExplorer) {
        self.explorer = explorer
    }

    deinit {
        toastTask?.cancel()
    }

    func loadUser() {
        let user = explorer.currentUser()
        defaultId = user.id
        deviceId = user.deviceId
        userId = user.userId
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
        toastTask?.cancel()
        showCopiedToast = true
        toastTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                self?.showCopiedToast = false
            } catch {
                // cancelled — no-op
            }
        }
    }
}

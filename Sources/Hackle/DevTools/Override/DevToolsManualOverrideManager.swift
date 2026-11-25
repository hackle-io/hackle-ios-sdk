import Foundation

final class DevToolsManualOverrideManager {

    private let userManager: UserManager
    private let workspaceManager: WorkspaceManager
    private let evaluationMode: EvaluationMode
    private let abTestOverrideStorage: DefaultExperimentManualOverrideStorage
    private let featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage
    private let devToolsAPI: DevToolsAPI

    init(
        userManager: UserManager,
        workspaceManager: WorkspaceManager,
        evaluationMode: EvaluationMode,
        abTestOverrideStorage: DefaultExperimentManualOverrideStorage,
        featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage,
        devToolsAPI: DevToolsAPI
    ) {
        self.userManager = userManager
        self.workspaceManager = workspaceManager
        self.evaluationMode = evaluationMode
        self.abTestOverrideStorage = abTestOverrideStorage
        self.featureFlagOverrideStorage = featureFlagOverrideStorage
        self.devToolsAPI = devToolsAPI
    }

    func set(type: DevToolsOverrideType, key: Int64, variation variationKey: String) -> DevToolsOverrideResult {
        guard evaluationMode == .local else {
            return .remoteMode
        }
        guard let workspace = workspaceManager.workspace(user: userManager.hackleUser()) as? WorkspaceConfig else {
            return .notReady
        }
        guard let experiment = experiment(workspace: workspace, type: type, key: key),
              let variation = experiment.getVariationOrNil(variationKey: variationKey) else {
            return .notFound
        }

        storage(type).set(experiment: experiment, variationId: variation.id)
        increment(type: type, operation: "set")

        let request = createOverrideRequest(variation: variation)
        switch type {
        case .abTest:
            devToolsAPI.addExperimentOverrides(experimentKey: experiment.key, request: request)
        case .featureFlag:
            devToolsAPI.addFeatureFlagOverrides(experimentKey: experiment.key, request: request)
        }
        return .success
    }

    func reset(type: DevToolsOverrideType, key: Int64) -> DevToolsOverrideResult {
        guard evaluationMode == .local else {
            return .remoteMode
        }
        guard let workspace = workspaceManager.workspace(user: userManager.hackleUser()) as? WorkspaceConfig else {
            return .notReady
        }
        guard let experiment = experiment(workspace: workspace, type: type, key: key) else {
            return .notFound
        }

        let storage = storage(type)
        let variation = storage.get(experiment: experiment).flatMap { experiment.getVariationOrNil(variationId: $0) }
        storage.remove(experiment: experiment)
        increment(type: type, operation: "reset")

        let request = createOverrideRequest(variation: variation)
        switch type {
        case .abTest:
            devToolsAPI.removeExperimentOverrides(experimentKey: experiment.key, request: request)
        case .featureFlag:
            devToolsAPI.removeFeatureFlagOverrides(experimentKey: experiment.key, request: request)
        }
        return .success
    }

    func resetAll(type: DevToolsOverrideType) -> DevToolsOverrideResult {
        guard evaluationMode == .local else {
            return .remoteMode
        }

        storage(type).clear()
        increment(type: type, operation: "reset.all")

        let request = createOverrideRequest()
        switch type {
        case .abTest:
            devToolsAPI.removeAllExperimentOverrides(request: request)
        case .featureFlag:
            devToolsAPI.removeAllFeatureFlagOverrides(request: request)
        }
        return .success
    }

    private func experiment(workspace: WorkspaceConfig, type: DevToolsOverrideType, key: Int64) -> ExperimentConfig? {
        switch type {
        case .abTest:
            return workspace.getExperimentConfigOrNil(experimentKey: key)
        case .featureFlag:
            return workspace.getFeatureFlagConfigOrNil(featureKey: key)
        }
    }

    private func storage(_ type: DevToolsOverrideType) -> DefaultExperimentManualOverrideStorage {
        switch type {
        case .abTest:
            return abTestOverrideStorage
        case .featureFlag:
            return featureFlagOverrideStorage
        }
    }

    private func createOverrideRequest(variation: Variation? = nil) -> OverrideRequest {
        let hackleUser = userManager.hackleUser()
        let user = userManager.currentUser.toBuilder()
            .id(hackleUser.id)
            .deviceId(hackleUser.deviceId)
            .userId(hackleUser.userId)
            .properties(hackleUser.properties)
            .build()
        return OverrideRequest(user: user, variation: variation)
    }

    private func increment(type: DevToolsOverrideType, operation: String) {
        let experimentType: ExperimentType = switch type {
        case .abTest: .abTest
        case .featureFlag: .featureFlag
        }
        let tags = [
            "experiment.type": experimentType.rawValue,
            "operation": operation
        ]
        Metrics.counter(name: "experiment.manual.override", tags: tags).increment()
    }
}

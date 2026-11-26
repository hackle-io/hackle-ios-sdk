import Foundation

final class DevToolsManualOverrideManager {

    private let userManager: UserManager
    private let workspaceManager: WorkspaceManager
    private let evaluationMode: EvaluationMode
    private let abTestOverrideStorage: DefaultExperimentManualOverrideStorage
    private let featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage

    init(
        userManager: UserManager,
        workspaceManager: WorkspaceManager,
        evaluationMode: EvaluationMode,
        abTestOverrideStorage: DefaultExperimentManualOverrideStorage,
        featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage
    ) {
        self.userManager = userManager
        self.workspaceManager = workspaceManager
        self.evaluationMode = evaluationMode
        self.abTestOverrideStorage = abTestOverrideStorage
        self.featureFlagOverrideStorage = featureFlagOverrideStorage
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

        storage(type).remove(experiment: experiment)
        increment(type: type, operation: "reset")
        return .success
    }

    func resetAll(type: DevToolsOverrideType) -> DevToolsOverrideResult {
        guard evaluationMode == .local else {
            return .remoteMode
        }

        storage(type).clear()
        increment(type: type, operation: "reset.all")
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

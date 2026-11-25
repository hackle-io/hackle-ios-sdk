import Foundation

final class DevToolsWorkspaceStateProvider {

    private let userManager: UserManager
    private let pushTokenManager: PushTokenManager
    private let decisionProcessor: DecisionProcessor
    private let devToolsDecisionProcessor: DevToolsDecisionProcessor
    private let abTestOverrideStorage: DefaultExperimentManualOverrideStorage
    private let featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage
    private let workspaceManager: WorkspaceManager
    private let evaluationMode: EvaluationMode
    private let clock: Clock

    init(
        userManager: UserManager,
        pushTokenManager: PushTokenManager,
        decisionProcessor: DecisionProcessor,
        devToolsDecisionProcessor: DevToolsDecisionProcessor,
        abTestOverrideStorage: DefaultExperimentManualOverrideStorage,
        featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage,
        workspaceManager: WorkspaceManager,
        evaluationMode: EvaluationMode,
        clock: Clock
    ) {
        self.userManager = userManager
        self.pushTokenManager = pushTokenManager
        self.decisionProcessor = decisionProcessor
        self.devToolsDecisionProcessor = devToolsDecisionProcessor
        self.abTestOverrideStorage = abTestOverrideStorage
        self.featureFlagOverrideStorage = featureFlagOverrideStorage
        self.workspaceManager = workspaceManager
        self.evaluationMode = evaluationMode
        self.clock = clock
    }

    func state() -> [String: Any]? {
        let user = userManager.hackleUser()
        guard let workspace = workspaceManager.workspace(user: user) else {
            return nil
        }
        let now = clock.now()

        var state: [String: Any] = [
            "timestamp": now.epochMillis,
            "evaluationMode": evaluationMode.description,
            "user": userState(user: user),
            "abTests": abTests(user: user),
            "featureFlags": featureFlags(user: user),
            "remoteConfigs": remoteConfigs(user: user),
            "inAppMessages": inAppMessages(user: user, timestamp: now)
        ]
        if evaluationMode == .remote, let evaluation = workspace as? WorkspaceEvaluation {
            state["evaluatedAt"] = evaluation.evaluatedAt
        }
        return state
    }

    private func userState(user: HackleUser) -> [String: Any] {
        var state: [String: Any] = [
            "identifiers": user.identifiers,
            "userProperties": user.properties,
            "hackleProperties": user.hackleProperties
        ]
        if let pushToken = pushTokenManager.currentToken() {
            state["pushToken"] = pushToken.value
        }
        return state
    }

    private func abTests(user: HackleUser) -> [[String: Any]] {
        guard let decisions = try? decisionProcessor.experiments(user: user) else {
            return []
        }
        return decisions.map { experiment, decision in
            withOverride([
                "key": experiment.key,
                "title": Self.title(experiment),
                "status": experiment.status.rawValue,
                "variation": decision.variation,
                "reason": decision.reason,
                "parameters": decision.parameters
            ], experiment: experiment, storage: abTestOverrideStorage)
        }
    }

    private func featureFlags(user: HackleUser) -> [[String: Any]] {
        guard let decisions = try? devToolsDecisionProcessor.featureFlags(user: user) else {
            return []
        }
        return decisions.map { experiment, decision in
            withOverride([
                "key": experiment.key,
                "title": Self.title(experiment),
                "status": experiment.status.rawValue,
                "isOn": decision.isOn,
                "reason": decision.reason,
                "parameters": decision.parameters
            ], experiment: experiment, storage: featureFlagOverrideStorage)
        }
    }

    private func remoteConfigs(user: HackleUser) -> [[String: Any]] {
        guard let evaluations = try? devToolsDecisionProcessor.remoteConfigs(user: user) else {
            return []
        }
        return evaluations.map { evaluation in
            [
                "key": evaluation.parameter.key,
                "type": evaluation.parameter.type.rawValue,
                "value": evaluation.remoteConfigResult.value?.rawValue.rawValue ?? NSNull(),
                "reason": evaluation.remoteConfigResult.reason
            ]
        }
    }

    private func inAppMessages(user: HackleUser, timestamp: Date) -> [[String: Any]] {
        guard let evaluations = try? devToolsDecisionProcessor.inAppMessages(user: user, timestamp: timestamp) else {
            return []
        }
        return evaluations.map { evaluation in
            [
                "key": evaluation.inAppMessage.key,
                "isEligible": evaluation.eligibilityResult.isEligible,
                "reason": evaluation.eligibilityResult.reason
            ]
        }
    }

    private func withOverride(
        _ item: [String: Any],
        experiment: Experiment,
        storage: DefaultExperimentManualOverrideStorage
    ) -> [String: Any] {
        guard evaluationMode == .local else {
            return item
        }
        let config = experiment as? ExperimentConfig
        var item = item
        item["variations"] = config?.variations.map(\.key) ?? []
        item["overriddenVariation"] = storage.get(experiment: experiment)
            .flatMap { config?.getVariationOrNil(variationId: $0)?.key } ?? NSNull()
        return item
    }

    private static func title(_ experiment: Experiment) -> Any {
        (experiment as? ExperimentConfig)?.name ?? NSNull()
    }
}

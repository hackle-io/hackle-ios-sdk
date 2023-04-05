import Foundation

protocol HackleInternalApp {

    func initialize(completion: @escaping () -> ())

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)]

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)]

    func track(event: Event, user: HackleUser)

    func track(event: Event, user: HackleUser, timestamp: Date)

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision
}

class DefaultHackleInternalApp: HackleInternalApp {

    private let evaluator: Evaluator
    private let workspaceFetcher: WorkspaceFetcher
    private let eventProcessor: UserEventProcessor

    init(evaluator: Evaluator, workspaceFetcher: WorkspaceFetcher, eventProcessor: UserEventProcessor) {
        self.evaluator = evaluator
        self.workspaceFetcher = workspaceFetcher
        self.eventProcessor = eventProcessor
    }

    static func create(
        workspaceFetcher: WorkspaceFetcher,
        eventProcessor: UserEventProcessor,
        manualOverrideStorage: ManualOverrideStorage
    ) -> DefaultHackleInternalApp {
        DefaultHackleInternalApp(
            evaluator: DefaultEvaluator(evaluationFlowFactory: DefaultEvaluationFlowFactory(manualOverrideStorage: manualOverrideStorage)),
            workspaceFetcher: workspaceFetcher,
            eventProcessor: eventProcessor
        )
    }

    func initialize(completion: @escaping () -> ()) {
        workspaceFetcher.initialize {
            completion()
        }
    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision {

        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return Decision.of(variation: defaultVariationKey, reason: DecisionReason.SDK_NOT_READY)
        }

        guard let experiment = workspace.getExperimentOrNil(experimentKey: experimentKey) else {
            return Decision.of(variation: defaultVariationKey, reason: DecisionReason.EXPERIMENT_NOT_FOUND)
        }

        let (evaluation, decision) = try evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
        eventProcessor.process(event: UserEvents.exposure(experiment: experiment, user: user, evaluation: evaluation))
        return decision
    }

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        var decisions = [(Experiment, Decision)]()
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return decisions
        }
        for experiment in workspace.experiments {
            let (_, decision) = try evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: "A")
            decisions.append((experiment, decision))
        }
        return decisions
    }

    private func evaluate(workspace: Workspace, experiment: Experiment, user: HackleUser, defaultVariationKey: String) throws -> (Evaluation, Decision) {
        let evaluation = try evaluator.evaluateExperiment(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
        let config: ParameterConfig = evaluation.config ?? EmptyParameterConfig.instance
        return (evaluation, Decision.of(variation: evaluation.variationKey, reason: evaluation.reason, config: config))
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return FeatureFlagDecision.off(reason: DecisionReason.SDK_NOT_READY)
        }

        guard let featureFlag = workspace.getFeatureFlagOrNil(featureKey: featureKey) else {
            return FeatureFlagDecision.off(reason: DecisionReason.FEATURE_FLAG_NOT_FOUND)
        }

        let (evaluation, decision) = try evaluate(workspace: workspace, featureFlag: featureFlag, user: user)
        eventProcessor.process(event: UserEvents.exposure(experiment: featureFlag, user: user, evaluation: evaluation))
        return decision
    }

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        var decisions = [(Experiment, FeatureFlagDecision)]()
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return decisions
        }
        for featureFlag in workspace.featureFlags {
            let (_, decision) = try evaluate(workspace: workspace, featureFlag: featureFlag, user: user)
            decisions.append((featureFlag, decision))
        }
        return decisions
    }

    private func evaluate(workspace: Workspace, featureFlag: Experiment, user: HackleUser) throws -> (Evaluation, FeatureFlagDecision) {
        let evaluation = try evaluator.evaluateExperiment(workspace: workspace, experiment: featureFlag, user: user, defaultVariationKey: "A")
        let config: ParameterConfig = evaluation.config ?? EmptyParameterConfig.instance
        if evaluation.variationKey == "A" {
            return (evaluation, FeatureFlagDecision.off(reason: evaluation.reason, config: config))
        } else {
            return (evaluation, FeatureFlagDecision.on(reason: evaluation.reason, config: config))
        }
    }

    func track(event: Event, user: HackleUser) {
        self.track(event: event, user: user, timestamp: Date())
    }

    func track(event: Event, user: HackleUser, timestamp: Date) {
        let eventType = workspaceFetcher.getWorkspaceOrNil()?.getEventTypeOrNil(eventTypeKey: event.key) ?? UndefinedEventType(key: event.key)
        let userEvent = UserEvents.track(eventType: eventType, event: event, timestamp: timestamp, user: user)
        eventProcessor.process(event: userEvent)
    }

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let parameter = workspace.getRemoteConfigParameter(parameterKey: parameterKey) else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.REMOTE_CONFIG_PARAMETER_NOT_FOUND)
        }

        let evaluation = try evaluator.evaluateRemoteConfig(workspace: workspace, parameter: parameter, user: user, defaultValue: defaultValue)
        eventProcessor.process(event: UserEvents.remoteConfig(parameter: parameter, user: user, evaluation: evaluation))
        return RemoteConfigDecision(value: evaluation.value, reason: evaluation.reason)
    }
}

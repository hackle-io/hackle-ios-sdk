import Foundation

protocol HackleInternalApp {

    func initialize(completion: @escaping () -> ())

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision

    func experiments(user: HackleUser) throws -> [Int: Decision]

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision

    func track(event: Event, user: HackleUser)

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

    static func create(workspaceFetcher: WorkspaceFetcher, eventProcessor: UserEventProcessor) -> DefaultHackleInternalApp {
        DefaultHackleInternalApp(
            evaluator: DefaultEvaluator(evaluationFlowFactory: DefaultEvaluationFlowFactory()),
            workspaceFetcher: workspaceFetcher,
            eventProcessor: eventProcessor
        )
    }

    func initialize(completion: @escaping () -> ()) {
        eventProcessor.initialize()
        eventProcessor.start()
        workspaceFetcher.fetchFromServer {
            Log.info("Hackle \(SdkVersion.CURRENT) started")
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

        let evaluation = try evaluator.evaluateExperiment(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
        eventProcessor.process(event: UserEvents.exposure(experiment: experiment, user: user, evaluation: evaluation))

        let config: ParameterConfig = evaluation.config ?? EmptyParameterConfig.instance
        return Decision.of(variation: evaluation.variationKey, reason: evaluation.reason, config: config)
    }

    func experiments(user: HackleUser) throws -> [Int: Decision] {
        var decisions = [Int: Decision]()
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return decisions
        }
        for experiment in workspace.experiments {
            let evaluation = try evaluator.evaluateExperiment(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: "A")
            let config: ParameterConfig = evaluation.config ?? EmptyParameterConfig.instance
            let decision = Decision.of(variation: evaluation.variationKey, reason: evaluation.reason, config: config)
            decisions[Int(experiment.key)] = decision
        }
        return decisions
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return FeatureFlagDecision.off(reason: DecisionReason.SDK_NOT_READY)
        }

        guard let featureFlag = workspace.getFeatureFlagOrNil(featureKey: featureKey) else {
            return FeatureFlagDecision.off(reason: DecisionReason.FEATURE_FLAG_NOT_FOUND)
        }

        let evaluation = try evaluator.evaluateExperiment(workspace: workspace, experiment: featureFlag, user: user, defaultVariationKey: "A")
        eventProcessor.process(event: UserEvents.exposure(experiment: featureFlag, user: user, evaluation: evaluation))

        let config: ParameterConfig = evaluation.config ?? EmptyParameterConfig.instance
        if evaluation.variationKey == "A" {
            return FeatureFlagDecision.off(reason: evaluation.reason, config: config)
        } else {
            return FeatureFlagDecision.on(reason: evaluation.reason, config: config)
        }
    }

    func track(event: Event, user: HackleUser) {
        let eventType = workspaceFetcher.getWorkspaceOrNil()?.getEventTypeOrNil(eventTypeKey: event.key) ?? UndefinedEventType(key: event.key)
        let userEvent = UserEvents.track(user: user, eventType: eventType, event: event)
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

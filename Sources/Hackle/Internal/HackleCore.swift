import Foundation

protocol HackleCore {

    func initialize(completion: @escaping () -> ())

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)]

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)]

    func track(event: Event, user: HackleUser)

    func track(event: Event, user: HackleUser, timestamp: Date)

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision
}

class DefaultHackleCore: HackleCore {

    private let experimentEvaluator: Evaluator
    private let remoteConfigEvaluator: Evaluator
    private let workspaceFetcher: WorkspaceFetcher
    private let eventFactory: UserEventFactory
    private let eventProcessor: UserEventProcessor

    init(
        experimentEvaluator: Evaluator,
        remoteConfigEvaluator: Evaluator,
        workspaceFetcher: WorkspaceFetcher,
        eventFactory: UserEventFactory,
        eventProcessor: UserEventProcessor
    ) {
        self.experimentEvaluator = experimentEvaluator
        self.remoteConfigEvaluator = remoteConfigEvaluator
        self.workspaceFetcher = workspaceFetcher
        self.eventFactory = eventFactory
        self.eventProcessor = eventProcessor
    }

    static func create(
        workspaceFetcher: WorkspaceFetcher,
        eventProcessor: UserEventProcessor,
        manualOverrideStorage: ManualOverrideStorage
    ) -> DefaultHackleCore {

        let delegatingEvaluator = DelegatingEvaluator()
        let flowFactory = DefaultEvaluationFlowFactory(evaluator: delegatingEvaluator, manualOverrideStorage: manualOverrideStorage)

        let experimentEvaluator = ExperimentEvaluator(evaluationFlowFactory: flowFactory)
        let remoteConfigEvaluator = RemoteConfigEvaluator(remoteConfigTargetRuleDeterminer: flowFactory.remoteConfigTargetRuleDeterminer)

        delegatingEvaluator.add(experimentEvaluator)
        delegatingEvaluator.add(remoteConfigEvaluator)

        return DefaultHackleCore(
            experimentEvaluator: experimentEvaluator,
            remoteConfigEvaluator: remoteConfigEvaluator,
            workspaceFetcher: workspaceFetcher,
            eventFactory: DefaultUserEventFactory(clock: SystemClock.instance),
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

        let request = ExperimentRequest.of(workspace: workspace, user: user, experiment: experiment, defaultVariationKey: defaultVariationKey)
        let (evaluation, decision) = try experimentInternal(request: request)

        let events = try eventFactory.create(request: request, evaluation: evaluation)
        eventProcessor.process(events: events)

        return decision
    }

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        var decisions = [(Experiment, Decision)]()
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return decisions
        }
        for experiment in workspace.experiments {
            let request = ExperimentRequest.of(workspace: workspace, user: user, experiment: experiment, defaultVariationKey: "A")
            let (_, decision) = try experimentInternal(request: request)
            decisions.append((experiment, decision))
        }
        return decisions
    }

    private func experimentInternal(request: ExperimentRequest) throws -> (ExperimentEvaluation, Decision) {
        let evaluation: ExperimentEvaluation = try experimentEvaluator.evaluate(request: request, context: Evaluators.context())
        let config: ParameterConfig = evaluation.config ?? EmptyParameterConfig.instance
        let decision = Decision.of(variation: evaluation.variationKey, reason: evaluation.reason, config: config)
        return (evaluation, decision)
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return FeatureFlagDecision.off(reason: DecisionReason.SDK_NOT_READY)
        }

        guard let featureFlag = workspace.getFeatureFlagOrNil(featureKey: featureKey) else {
            return FeatureFlagDecision.off(reason: DecisionReason.FEATURE_FLAG_NOT_FOUND)
        }

        let request = ExperimentRequest.of(workspace: workspace, user: user, experiment: featureFlag, defaultVariationKey: "A")
        let (evaluation, decision) = try featureFlagInternal(request: request)

        let events = try eventFactory.create(request: request, evaluation: evaluation)
        eventProcessor.process(events: events)

        return decision
    }

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        var decisions = [(Experiment, FeatureFlagDecision)]()
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return decisions
        }
        for featureFlag in workspace.featureFlags {
            let request = ExperimentRequest.of(workspace: workspace, user: user, experiment: featureFlag, defaultVariationKey: "A")
            let (_, decision) = try featureFlagInternal(request: request)
            decisions.append((featureFlag, decision))
        }
        return decisions
    }

    private func featureFlagInternal(request: ExperimentRequest) throws -> (ExperimentEvaluation, FeatureFlagDecision) {
        let evaluation: ExperimentEvaluation = try experimentEvaluator.evaluate(request: request, context: Evaluators.context())
        let config: ParameterConfig = evaluation.config ?? EmptyParameterConfig.instance

        let decision = evaluation.variationKey == "A"
            ? FeatureFlagDecision.off(reason: evaluation.reason, config: config)
            : FeatureFlagDecision.on(reason: evaluation.reason, config: config)

        return (evaluation, decision)
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

        let request = RemoteConfigRequest.of(workspace: workspace, user: user, parameter: parameter, defaultValue: defaultValue)
        let evaluation: RemoteConfigEvaluation = try remoteConfigEvaluator.evaluate(request: request, context: Evaluators.context())

        let events = try eventFactory.create(request: request, evaluation: evaluation)
        eventProcessor.process(events: events)

        return RemoteConfigDecision(value: evaluation.value, reason: evaluation.reason)
    }
}

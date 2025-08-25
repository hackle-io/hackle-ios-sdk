import Foundation

protocol HackleCore {

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)]

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)]

    func track(event: Event, user: HackleUser)

    func track(event: Event, user: HackleUser, timestamp: Date)

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision

    func evaluate<Evaluator: ContextualEvaluator>(request: Evaluator.Request, context: EvaluatorContext, evaluator: Evaluator) throws -> Evaluator.Evaluation
}

class DefaultHackleCore: HackleCore {

    private let experimentEvaluator: Evaluator
    private let remoteConfigEvaluator: Evaluator
    private let inAppMessageEvaluator: Evaluator
    private let workspaceFetcher: WorkspaceFetcher
    private let eventFactory: UserEventFactory
    private let eventProcessor: UserEventProcessor
    private let clock: Clock

    init(
        experimentEvaluator: Evaluator,
        remoteConfigEvaluator: Evaluator,
        inAppMessageEvaluator: Evaluator,
        workspaceFetcher: WorkspaceFetcher,
        eventFactory: UserEventFactory,
        eventProcessor: UserEventProcessor,
        clock: Clock
    ) {
        self.experimentEvaluator = experimentEvaluator
        self.remoteConfigEvaluator = remoteConfigEvaluator
        self.inAppMessageEvaluator = inAppMessageEvaluator
        self.workspaceFetcher = workspaceFetcher
        self.eventFactory = eventFactory
        self.eventProcessor = eventProcessor
        self.clock = clock
    }

    static func create(
        workspaceFetcher: WorkspaceFetcher,
        eventProcessor: UserEventProcessor,
        manualOverrideStorage: ManualOverrideStorage
    ) -> DefaultHackleCore {

        let delegatingEvaluator = DelegatingEvaluator()
        let context = EvaluationContext.shared
        context.initialize(evaluator: delegatingEvaluator, manualOverrideStorage: manualOverrideStorage, clock: SystemClock.shared)
        let flowFactory = DefaultEvaluationFlowFactory(context: context)

        let experimentEvaluator = ExperimentEvaluator(evaluationFlowFactory: flowFactory)
        let remoteConfigEvaluator = RemoteConfigEvaluator(remoteConfigTargetRuleDeterminer: context.get(RemoteConfigTargetRuleDeterminer.self)!)
        let inAppMessageEvaluator = InAppMessageEligibilityEvaluator(evaluationFlowFactory: flowFactory)

        delegatingEvaluator.add(experimentEvaluator)
        delegatingEvaluator.add(remoteConfigEvaluator)

        return DefaultHackleCore(
            experimentEvaluator: experimentEvaluator,
            remoteConfigEvaluator: remoteConfigEvaluator,
            inAppMessageEvaluator: inAppMessageEvaluator,
            workspaceFetcher: workspaceFetcher,
            eventFactory: DefaultUserEventFactory(clock: SystemClock.shared),
            eventProcessor: eventProcessor,
            clock: SystemClock.shared
        )
    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision {

        guard let workspace = workspaceFetcher.fetch() else {
            return Decision.of(experiment: nil, variation: defaultVariationKey, reason: DecisionReason.SDK_NOT_READY)
        }

        guard let experiment = workspace.getExperimentOrNil(experimentKey: experimentKey) else {
            return Decision.of(experiment: nil, variation: defaultVariationKey, reason: DecisionReason.EXPERIMENT_NOT_FOUND)
        }

        let request = ExperimentRequest.of(workspace: workspace, user: user, experiment: experiment, defaultVariationKey: defaultVariationKey)
        let (evaluation, decision) = try experimentInternal(request: request)

        let events = eventFactory.create(request: request, evaluation: evaluation)
        eventProcessor.process(events: events)

        return decision
    }

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        var decisions = [(Experiment, Decision)]()
        guard let workspace = workspaceFetcher.fetch() else {
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
        let decision = Decision.of(experiment: evaluation.experiment, variation: evaluation.variationKey, reason: evaluation.reason, config: config)
        return (evaluation, decision)
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        guard let workspace = workspaceFetcher.fetch() else {
            return FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.SDK_NOT_READY)
        }

        guard let featureFlag = workspace.getFeatureFlagOrNil(featureKey: featureKey) else {
            return FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.FEATURE_FLAG_NOT_FOUND)
        }

        let request = ExperimentRequest.of(workspace: workspace, user: user, experiment: featureFlag, defaultVariationKey: "A")
        let (evaluation, decision) = try featureFlagInternal(request: request)

        let events = eventFactory.create(request: request, evaluation: evaluation)
        eventProcessor.process(events: events)

        return decision
    }

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        var decisions = [(Experiment, FeatureFlagDecision)]()
        guard let workspace = workspaceFetcher.fetch() else {
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
            ? FeatureFlagDecision.off(featureFlag: evaluation.experiment, reason: evaluation.reason, config: config)
            : FeatureFlagDecision.on(featureFlag: evaluation.experiment, reason: evaluation.reason, config: config)

        return (evaluation, decision)
    }

    func track(event: Event, user: HackleUser) {
        self.track(event: event, user: user, timestamp: clock.now())
    }

    func track(event: Event, user: HackleUser, timestamp: Date) {
        let eventType = workspaceFetcher.fetch()?.getEventTypeOrNil(eventTypeKey: event.key) ?? UndefinedEventType(key: event.key)
        let userEvent = UserEvents.track(eventType: eventType, event: event, timestamp: timestamp, user: user)
        eventProcessor.process(event: userEvent)
    }

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        guard let workspace = workspaceFetcher.fetch() else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let parameter = workspace.getRemoteConfigParameterOrNil(parameterKey: parameterKey) else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.REMOTE_CONFIG_PARAMETER_NOT_FOUND)
        }

        let request = RemoteConfigRequest.of(workspace: workspace, user: user, parameter: parameter, defaultValue: defaultValue)
        let evaluation: RemoteConfigEvaluation = try remoteConfigEvaluator.evaluate(request: request, context: Evaluators.context())

        let events = eventFactory.create(request: request, evaluation: evaluation)
        eventProcessor.process(events: events)

        return RemoteConfigDecision(value: evaluation.value, reason: evaluation.reason)
    }

    func evaluate<Evaluator: ContextualEvaluator>(request: Evaluator.Request, context: EvaluatorContext, evaluator: Evaluator) throws -> Evaluator.Evaluation {
        let evaluation: Evaluator.Evaluation = try evaluator.evaluate(request: request, context: context)
        let events = eventFactory.create(request: request, evaluation: evaluation)
        eventProcessor.process(events: events)
        return evaluation
    }
}

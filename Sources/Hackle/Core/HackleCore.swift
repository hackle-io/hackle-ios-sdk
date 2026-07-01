import Foundation

protocol HackleCore {

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)]

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)]

    func track(event: Event, user: HackleUser)

    func track(event: Event, user: HackleUser, timestamp: Date)

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision
}

class DefaultHackleCore: HackleCore {

    private let workspaceFetcher: WorkspaceFetcher
    private let decisionProcessor: DecisionProcessor
    private let eventProcessor: UserEventProcessor
    private let clock: Clock

    init(
        workspaceFetcher: WorkspaceFetcher,
        decisionProcessor: DecisionProcessor,
        eventProcessor: UserEventProcessor,
        clock: Clock
    ) {
        self.workspaceFetcher = workspaceFetcher
        self.decisionProcessor = decisionProcessor
        self.eventProcessor = eventProcessor
        self.clock = clock
    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision {
        try decisionProcessor.experiment(experimentKey: experimentKey, user: user, defaultVariationKey: defaultVariationKey)
    }

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        try decisionProcessor.experiments(user: user)
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        try decisionProcessor.featureFlag(featureKey: featureKey, user: user)
    }

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        try decisionProcessor.featureFlags(user: user)
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
        try decisionProcessor.remoteConfig(parameterKey: parameterKey, user: user, defaultValue: defaultValue)
    }
}

import Foundation

protocol HackleCore {

    func experiment(experimentKey: Experiment.Key, user: HackleUser) throws -> Decision

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)]

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)]

    func track(event: Event, user: HackleUser)

    func track(event: Event, user: HackleUser, timestamp: Date)

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision
}

class DefaultHackleCore: HackleCore {

    private let workspaceManager: WorkspaceManager
    private let decisionProcessor: DecisionProcessor
    private let eventProcessor: UserEventProcessor
    private let clock: Clock

    init(
        workspaceManager: WorkspaceManager,
        decisionProcessor: DecisionProcessor,
        eventProcessor: UserEventProcessor,
        clock: Clock
    ) {
        self.workspaceManager = workspaceManager
        self.decisionProcessor = decisionProcessor
        self.eventProcessor = eventProcessor
        self.clock = clock
    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser) throws -> Decision {
        try decisionProcessor.experiment(experimentKey: experimentKey, user: user)
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
        let workspace = workspaceManager.workspace(user: user)
        let userEvent = UserEvents.track(event: event, workspace: workspace, timestamp: timestamp, user: user)
        eventProcessor.process(event: userEvent)
    }

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        try decisionProcessor.remoteConfig(parameterKey: parameterKey, user: user, defaultValue: defaultValue)
    }
}

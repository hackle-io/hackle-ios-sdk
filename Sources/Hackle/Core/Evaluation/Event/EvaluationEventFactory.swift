import Foundation

class EvaluationEventFactory {

    private static let ROOT_TYPE = "$targetingRootType"
    private static let ROOT_ID = "$targetingRootId"

    private static let CONFIG_ID_PROPERTY_KEY = "$parameterConfigurationId"
    private static let EXPERIMENT_VERSION_KEY = "$experiment_version"
    private static let EXECUTION_VERSION_KEY = "$execution_version"

    private let clock: Clock

    init(clock: Clock) {
        self.clock = clock
    }

    func create(response: EvaluateResponse) -> [UserEvent] {
        let timestamp = clock.now()
        var events: [UserEvent] = []
        if let root = create(user: response.user, workspace: response.workspace, evaluation: response.evaluation, timestamp: timestamp, properties: PropertiesBuilder()) {
            events.append(root)
        }
        for reference in response.references {
            let properties = PropertiesBuilder()
            properties.add(EvaluationEventFactory.ROOT_TYPE, response.evaluation.entity.serviceType.rawValue)
            properties.add(EvaluationEventFactory.ROOT_ID, response.evaluation.entity.id)
            if let event = create(user: response.user, workspace: response.workspace, evaluation: reference, timestamp: timestamp, properties: properties) {
                events.append(event)
            }
        }
        return events
    }

    private func create(user: HackleUser, workspace: Workspace, evaluation: Evaluation, timestamp: Date, properties: PropertiesBuilder) -> UserEvent? {
        switch evaluation {
        case let evaluation as ExperimentEvaluation:
            properties.add(EvaluationEventFactory.CONFIG_ID_PROPERTY_KEY, evaluation.experimentResult.variation.parameterConfiguration?.id)
            properties.add(EvaluationEventFactory.EXPERIMENT_VERSION_KEY, evaluation.experiment.version)
            properties.add(EvaluationEventFactory.EXECUTION_VERSION_KEY, evaluation.experiment.executionVersion)
            return UserEvents.exposure(
                user: user,
                workspace: workspace,
                evaluation: evaluation,
                properties: properties.build(),
                timestamp: timestamp
            )
        case let evaluation as RemoteConfigEvaluation:
            return UserEvents.remoteConfig(
                user: user,
                workspace: workspace,
                evaluation: evaluation,
                properties: properties.build(),
                timestamp: timestamp
            )
        default:
            return nil
        }
    }
}

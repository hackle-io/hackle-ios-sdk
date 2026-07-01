import Foundation

class EvaluationEventFactory {

    private static let ROOT_TYPE = "$targetingRootType"
    private static let ROOT_ID = "$targetingRootId"

    private let clock: Clock

    init(clock: Clock) {
        self.clock = clock
    }

    func create(response: EvaluateResponse) -> [UserEvent] {
        let timestamp = clock.now()
        var events: [UserEvent] = []
        if let root = create(user: response.user, evaluation: response.evaluation, timestamp: timestamp, properties: PropertiesBuilder()) {
            events.append(root)
        }
        for reference in response.references {
            let properties = PropertiesBuilder()
            properties.add(EvaluationEventFactory.ROOT_TYPE, response.evaluation.entity.serviceType.rawValue)
            properties.add(EvaluationEventFactory.ROOT_ID, response.evaluation.entity.id)
            if let event = create(user: response.user, evaluation: reference, timestamp: timestamp, properties: properties) {
                events.append(event)
            }
        }
        return events
    }

    // step 3: ExperimentEvaluation → UserEvents.exposure ($parameterConfigurationId / $experiment_version / $execution_version / evaluation.properties 키는 기존 DefaultUserEventFactory에서 그대로 이관)
    // step 4: RemoteConfigEvaluation → UserEvents.remoteConfig
    private func create(user: HackleUser, evaluation: Evaluation, timestamp: Date, properties: PropertiesBuilder) -> UserEvent? {
        return nil
    }
}

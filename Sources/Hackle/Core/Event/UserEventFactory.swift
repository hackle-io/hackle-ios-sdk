//
//  UserEventFactory.swift
//  Hackle
//
//  Created by yong on 2023/04/19.
//

import Foundation

protocol UserEventFactory {
    func create(request: EvaluatorRequest, evaluation: EvaluatorEvaluation) throws -> [UserEvent]
}


class DefaultUserEventFactory: UserEventFactory {

    private let clock: Clock

    init(clock: Clock) {
        self.clock = clock
    }

    private static let CONFIG_ID_PROPERTY_KEY = "$parameterConfigurationId"
    private static let ROOT_TYPE = "$targetingRootType"
    private static let ROOT_ID = "$targetingRootId"

    private static let EXPERIMENT_VERSION_KEY = "$experiment_version"
    private static let EXECUTION_VERSION_KEY = "$execution_version"

    func create(request: EvaluatorRequest, evaluation: EvaluatorEvaluation) throws -> [UserEvent] {

        let timestamp = clock.now()
        var events: [UserEvent] = []

        if let rootEvent = try create(request: request, evaluation: evaluation, timestamp: timestamp, properties: PropertiesBuilder()) {
            events.append(rootEvent)
        }

        for targetEvaluation in evaluation.targetEvaluations {
            let properties = PropertiesBuilder()
            properties.add(DefaultUserEventFactory.ROOT_TYPE, request.key.type.rawValue)
            properties.add(DefaultUserEventFactory.ROOT_ID, request.key.id)
            if let targetEvent = try create(request: request, evaluation: targetEvaluation, timestamp: timestamp, properties: properties) {
                events.append(targetEvent)
            }
        }
        return events
    }

    private func create(
        request: EvaluatorRequest,
        evaluation: EvaluatorEvaluation,
        timestamp: Date,
        properties: PropertiesBuilder
    ) throws -> UserEvent? {

        switch evaluation {
        case let evaluation as ExperimentEvaluation:
            properties.add(DefaultUserEventFactory.CONFIG_ID_PROPERTY_KEY, evaluation.config?.id)
            properties.add(DefaultUserEventFactory.EXPERIMENT_VERSION_KEY, evaluation.experiment.version)
            properties.add(DefaultUserEventFactory.EXECUTION_VERSION_KEY, evaluation.experiment.executionVersion)
            return UserEvents.exposure(
                user: request.user,
                evaluation: evaluation,
                properties: properties.build(),
                timestamp: timestamp
            )
        case let evaluation as RemoteConfigEvaluation:
            properties.add(evaluation.properties)
            return UserEvents.remoteConfig(
                user: request.user,
                evaluation: evaluation,
                properties: properties.build(),
                timestamp: timestamp
            )
        case _ as InAppMessageEligibilityEvaluation:
            return nil
        default:
            throw HackleError.error("Unsupported Evaluation [\(evaluation)]")
        }
    }
}

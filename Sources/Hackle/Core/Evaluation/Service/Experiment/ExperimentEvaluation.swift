//
//  ExperimentEvaluation.swift
//  Hackle
//

import Foundation

final class ExperimentEvaluation: Evaluation, Equatable {
    let experiment: Experiment
    let experimentResult: ExperimentEvaluateResult

    var entity: Entity { experiment }
    var result: EvaluateResult { experimentResult }

    init(entity: Experiment, result: ExperimentEvaluateResult) {
        self.experiment = entity
        self.experimentResult = result
    }

    static func ==(lhs: ExperimentEvaluation, rhs: ExperimentEvaluation) -> Bool {
        lhs.experiment.entityKey == rhs.experiment.entityKey
            && lhs.experimentResult.variation.id == rhs.experimentResult.variation.id
            && lhs.experimentResult.variation.key == rhs.experimentResult.variation.key
            && lhs.experimentResult.reason == rhs.experimentResult.reason
            && lhs.experimentResult.variation.parameterConfiguration?.id == rhs.experimentResult.variation.parameterConfiguration?.id
    }
}

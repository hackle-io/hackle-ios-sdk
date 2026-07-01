//
//  ExperimentEvaluation.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
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
            && lhs.experimentResult.variationId == rhs.experimentResult.variationId
            && lhs.experimentResult.variationKey == rhs.experimentResult.variationKey
            && lhs.experimentResult.reason == rhs.experimentResult.reason
            && lhs.experimentResult.config?.id == rhs.experimentResult.config?.id
    }
}

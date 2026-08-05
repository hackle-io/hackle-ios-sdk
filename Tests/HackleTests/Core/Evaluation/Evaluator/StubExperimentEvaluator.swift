//
//  StubExperimentEvaluator.swift
//  HackleTests
//

import Foundation
@testable import Hackle

/// call 횟수를 세고 설정된 evaluation을 반환하는 공유 experiment evaluator stub.
/// evaluation 미설정 시 기본 평가를 만든다.
final class StubExperimentEvaluator: ExperimentEvaluator {
    let eventRecorder: EvaluationEventRecorder
    var evaluation: ExperimentEvaluation?
    var call: Int = 0

    init() {
        self.eventRecorder = MockEvaluationEventRecorder()
    }

    func doEvaluate(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> ExperimentEvaluateResponse {
        call += 1
        let evaluation = evaluation ?? ExperimentEvaluation(
            entity: request.experiment,
            result: ExperimentEvaluateResult.of(reason: DecisionReason.TRAFFIC_ALLOCATED, variation: request.experimentConfig.variations.first!)
        )
        return ExperimentEvaluateResponse(user: request.user, workspace: request.workspace, evaluation: evaluation, references: [])
    }
}

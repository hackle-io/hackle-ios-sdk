//
//  StubExperimentEvaluator.swift
//  HackleTests
//

import Foundation
@testable import Hackle

/// call 횟수를 세고 설정된 evaluation을 반환하는 공유 experiment evaluator stub.
/// evaluation 미설정 시 defaultReason으로 기본 평가를 만든다.
final class StubExperimentEvaluator: ExperimentEvaluator {
    let eventRecorder: EvaluationEventRecorder
    var evaluation: ExperimentEvaluation?
    var call: Int = 0

    private let defaultReason: String
    private let includeContextReferences: Bool

    init(defaultReason: String = DecisionReason.TRAFFIC_ALLOCATED, includeContextReferences: Bool = false) {
        self.eventRecorder = MockEvaluationEventRecorder()
        self.defaultReason = defaultReason
        self.includeContextReferences = includeContextReferences
    }

    func doEvaluate(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> ExperimentEvaluateResponse {
        call += 1
        let evaluation = evaluation ?? ExperimentEvaluation(
            entity: request.experiment,
            result: ExperimentEvaluateResult.of(reason: defaultReason, variation: request.experimentConfig.variations.first!)
        )
        let references = includeContextReferences ? context.references : []
        return ExperimentEvaluateResponse(user: request.user, workspace: request.workspace, evaluation: evaluation, references: references)
    }
}

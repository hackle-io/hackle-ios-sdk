import Foundation

class InAppMessageLayoutExperimentEvaluator: ExperimentReferenceLocalEvaluator {

    let evaluator: Evaluator

    init(evaluator: DelegatingEvaluator) {
        self.evaluator = evaluator
    }

    func resolveEvaluation(sourceRequest: LocalEvaluateRequest, experimentResponse: ExperimentEvaluateResponse) throws -> ExperimentEvaluation {
        experimentResponse.experimentEvaluation
    }
}

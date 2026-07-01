import Foundation

class EvaluateProcessor {

    private let evaluatorFactory: EvaluatorFactory

    init(evaluatorFactory: EvaluatorFactory) {
        self.evaluatorFactory = evaluatorFactory
    }

    // 타입드 진입점(experiment/remoteConfig/inAppMessage x2)은 step 3/4/5에서 추가.
    // static create(...)는 step 6에서 추가.

    fileprivate func evaluate<Res: EvaluateResponse>(evaluator: any Evaluator, request: EvaluateRequest) throws -> Res {
        let response: Res = try evaluator.evaluate(request: request, context: Evaluators.context())
        if request.record {
            evaluator.record(request: request, response: response)
        }
        return response
    }
}

extension EvaluateProcessor {
    func experiment(_ request: ExperimentEvaluateRequest) throws -> ExperimentEvaluateResponse {
        try evaluate(evaluator: try evaluatorFactory.experiment(request), request: request)
    }
}

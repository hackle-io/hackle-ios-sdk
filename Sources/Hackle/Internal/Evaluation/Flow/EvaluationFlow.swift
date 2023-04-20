import Foundation

protocol EvaluationFlow {
    func evaluate(request: ExperimentRequest, context: EvaluatorContext) throws -> ExperimentEvaluation
}

enum DefaultEvaluationFlow: EvaluationFlow {

    case end
    case decision(flowEvaluator: FlowEvaluator, nextFlow: EvaluationFlow)

    func evaluate(request: ExperimentRequest, context: EvaluatorContext) throws -> ExperimentEvaluation {
        switch self {
        case .end:
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)
        case .decision(let flowEvaluator, let nextFlow):
            return try flowEvaluator.evaluate(request: request, context: context, nextFlow: nextFlow)
        }
    }

    static func of(_ flowEvaluators: FlowEvaluator...) -> EvaluationFlow {
        var flow: EvaluationFlow = DefaultEvaluationFlow.end
        for flowEvaluator in flowEvaluators.reversed() {
            flow = DefaultEvaluationFlow.decision(flowEvaluator: flowEvaluator, nextFlow: flow)
        }
        return flow
    }
}

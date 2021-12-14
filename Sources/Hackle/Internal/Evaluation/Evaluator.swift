import Foundation

protocol Evaluator {
    func evaluate(workspace: Workspace, experiment: Experiment, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Evaluation
}

class DefaultEvaluator: Evaluator {

    private let evaluationFlowFactory: EvaluationFlowFactory

    init(evaluationFlowFactory: EvaluationFlowFactory) {
        self.evaluationFlowFactory = evaluationFlowFactory
    }

    func evaluate(workspace: Workspace, experiment: Experiment, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Evaluation {
        let evaluationFlow = evaluationFlowFactory.getFlow(experimentType: experiment.type)
        return try evaluationFlow.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
    }
}

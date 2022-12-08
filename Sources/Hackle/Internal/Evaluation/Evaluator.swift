import Foundation

protocol Evaluator {
    func evaluateExperiment(workspace: Workspace, experiment: Experiment, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Evaluation
    func evaluateRemoteConfig(workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigEvaluation
}

class DefaultEvaluator: Evaluator {

    private let evaluationFlowFactory: EvaluationFlowFactory

    init(evaluationFlowFactory: EvaluationFlowFactory) {
        self.evaluationFlowFactory = evaluationFlowFactory
    }

    func evaluateExperiment(workspace: Workspace, experiment: Experiment, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Evaluation {
        let evaluationFlow = evaluationFlowFactory.getFlow(experimentType: experiment.type)
        return try evaluationFlow.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
    }

    func evaluateRemoteConfig(workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigEvaluation {

        let propertiesBuilder = PropertiesBuilder()
            .add(key: "requestValueType", value: defaultValue.type.rawValue)
            .add(key: "requestDefaultValue", value: defaultValue.rawValue)

        if user.identifiers[parameter.identifierType] == nil {
            return RemoteConfigEvaluation.of(valueId: nil, value: defaultValue, reason: DecisionReason.IDENTIFIER_NOT_FOUND, propertiesBuilder: propertiesBuilder)
        }

        let targetRuleDeterminer = evaluationFlowFactory.remoteConfigTargetRuleDeterminer
        if let targetRule = try targetRuleDeterminer.determineTargetRuleOrNil(workspace: workspace, parameter: parameter, user: user) {
            propertiesBuilder.add(key: "targetRuleKey", value: targetRule.key)
            propertiesBuilder.add(key: "targetRuleName", value: targetRule.name)
            return evaluation(parameterValue: targetRule.value, reason: DecisionReason.TARGET_RULE_MATCH, defaultValue: defaultValue, propertiesBuilder: propertiesBuilder)
        }

        return evaluation(parameterValue: parameter.defaultValue, reason: DecisionReason.DEFAULT_RULE, defaultValue: defaultValue, propertiesBuilder: propertiesBuilder)
    }

    private func evaluation(parameterValue: RemoteConfigParameter.Value, reason: String, defaultValue: HackleValue, propertiesBuilder: PropertiesBuilder) -> RemoteConfigEvaluation {
        if parameterValue.rawValue.type != defaultValue.type {
            return RemoteConfigEvaluation.of(valueId: nil, value: defaultValue, reason: DecisionReason.TYPE_MISMATCH, propertiesBuilder: propertiesBuilder)
        } else {
            return RemoteConfigEvaluation.of(valueId: parameterValue.id, value: parameterValue.rawValue, reason: reason, propertiesBuilder: propertiesBuilder)
        }
    }
}

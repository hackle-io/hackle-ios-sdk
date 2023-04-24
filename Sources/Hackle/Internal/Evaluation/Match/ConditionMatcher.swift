import Foundation

protocol ConditionMatcher {
    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool
}

protocol ConditionMatcherFactory {
    func getMatcher(_ type: Target.KeyType) -> ConditionMatcher
}

class DefaultConditionMatcherFactory: ConditionMatcherFactory {

    private let userConditionMatcher: ConditionMatcher
    private let segmentConditionMatcher: ConditionMatcher
    private let experimentConditionMatcher: ConditionMatcher

    init(evaluator: Evaluator) {
        let valueOperatorMatcher = DefaultValueOperatorMatcher(
            valueMatcherFactory: ValueMatcherFactory(),
            operatorMatcherFactory: OperatorMatcherFactory()
        )

        userConditionMatcher = UserConditionMatcher(
            userValueResolver: DefaultUserValueResolver(),
            valueOperatorMatcher: valueOperatorMatcher
        )

        segmentConditionMatcher = SegmentConditionMatcher(
            segmentMatcher: DefaultSegmentMatcher(userConditionMatcher: userConditionMatcher)
        )

        experimentConditionMatcher = ExperimentConditionMatcher(
            abTestMatcher: AbTestConditionMatcher(evaluator: evaluator, valueOperatorMatcher: valueOperatorMatcher),
            featureFlagMatcher: FeatureFlagConditionMatcher(evaluator: evaluator, valueOperatorMatcher: valueOperatorMatcher)
        )
    }


    func getMatcher(_ type: Target.KeyType) -> ConditionMatcher {
        switch type {
        case .userId, .userProperty, .hackleProperty: return userConditionMatcher
        case .segment: return segmentConditionMatcher
        case .abTest, .featureFlag: return experimentConditionMatcher
        }
    }
}

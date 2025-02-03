import Foundation

protocol ConditionMatcher {
    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool
}

protocol ConditionMatcherFactory {
    func getMatcher(_ type: Target.KeyType) -> ConditionMatcher
}

class DefaultConditionMatcherFactory: ConditionMatcherFactory {

    private let userConditionMatcher: ConditionMatcher
    private let eventConditionMatcher: ConditionMatcher
    private let segmentConditionMatcher: ConditionMatcher
    private let experimentConditionMatcher: ConditionMatcher
    private let cohortConditionMatcher: ConditionMatcher
    private let targetEventConditionMatcher: ConditionMatcher

    init(evaluator: Evaluator) {
        let valueOperatorMatcher = DefaultValueOperatorMatcher(
            valueMatcherFactory: ValueMatcherFactory(),
            operatorMatcherFactory: OperatorMatcherFactory()
        )

        userConditionMatcher = UserConditionMatcher(
            userValueResolver: DefaultUserValueResolver(),
            valueOperatorMatcher: valueOperatorMatcher
        )

        eventConditionMatcher = EventConditionMatcher(
            eventValueResolver: DefaultEventValueResolver(),
            valueOperatorMatcher: valueOperatorMatcher
        )

        segmentConditionMatcher = SegmentConditionMatcher(
            segmentMatcher: DefaultSegmentMatcher(userConditionMatcher: userConditionMatcher)
        )

        experimentConditionMatcher = ExperimentConditionMatcher(
            abTestMatcher: AbTestConditionMatcher(evaluator: evaluator, valueOperatorMatcher: valueOperatorMatcher),
            featureFlagMatcher: FeatureFlagConditionMatcher(evaluator: evaluator, valueOperatorMatcher: valueOperatorMatcher)
        )

        cohortConditionMatcher = CohortConditionMatcher(
            valueOperatorMatcher: valueOperatorMatcher
        )
        
        targetEventConditionMatcher = TargetEventConditionMatcher(
            numberOfEventsInDaysMatcher: NumberOfEventsInDaysMatcher(valueOperatorMatcher: valueOperatorMatcher),
            numberOfEventsWithPropertyInDaysMatcher: NumberOfEventsWithPropertyInDaysMatcher(valueOperatorMatcher: valueOperatorMatcher)
        )
    }


    func getMatcher(_ type: Target.KeyType) -> ConditionMatcher {
        switch type {
        case .userId, .userProperty, .hackleProperty: return userConditionMatcher
        case .eventProperty: return eventConditionMatcher
        case .segment: return segmentConditionMatcher
        case .abTest, .featureFlag: return experimentConditionMatcher
        case .cohort: return cohortConditionMatcher
        case .numberOfEventsInDays, .numberOfEventsWithPropertyInDays: return targetEventConditionMatcher
        }
    }
}

import Foundation

protocol TargetMatcher {
    func matches(request: EvaluatorRequest, context: EvaluatorContext, target: Target) throws -> Bool
}

extension TargetMatcher {
    func anyMatches(request: EvaluatorRequest, context: EvaluatorContext, targets: [Target]) throws -> Bool {
        if targets.isEmpty {
            return true
        }
        return try targets.contains { it in
            try matches(request: request, context: context, target: it)
        }
    }
}


class DefaultTargetMatcher: TargetMatcher {

    private let conditionMatcherFactory: ConditionMatcherFactory

    init(conditionMatcherFactory: ConditionMatcherFactory) {
        self.conditionMatcherFactory = conditionMatcherFactory
    }

    func matches(request: EvaluatorRequest, context: EvaluatorContext, target: Target) throws -> Bool {
        try target.conditions.allSatisfy { it in
            try matches(request: request, context: context, condition: it)
        }
    }

    private func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        let conditionMatcher = conditionMatcherFactory.getMatcher(condition.key.type)
        return try conditionMatcher.matches(request: request, context: context, condition: condition)
    }
}

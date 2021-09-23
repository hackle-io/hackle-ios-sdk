import Foundation

protocol TargetMatcher {
    func matches(target: Target, workspace: Workspace, user: User) -> Bool
}


class DefaultTargetMatcher: TargetMatcher {

    private let conditionMatcherFactory: ConditionMatcherFactory

    init(conditionMatcherFactory: ConditionMatcherFactory) {
        self.conditionMatcherFactory = conditionMatcherFactory
    }

    func matches(target: Target, workspace: Workspace, user: User) -> Bool {
        target.conditions.allSatisfy { it in
            matches(condition: it, workspace: workspace, user: user)
        }
    }

    private func matches(condition: Target.Condition, workspace: Workspace, user: User) -> Bool {
        let conditionMatcher = conditionMatcherFactory.getMatcher(condition.key.type)
        return conditionMatcher.matches(condition: condition, workspace: workspace, user: user)
    }
}

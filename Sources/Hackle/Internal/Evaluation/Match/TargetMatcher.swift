import Foundation

protocol TargetMatcher {
    func matches(target: Target, workspace: Workspace, user: HackleUser) throws -> Bool
}


class DefaultTargetMatcher: TargetMatcher {

    private let conditionMatcherFactory: ConditionMatcherFactory

    init(conditionMatcherFactory: ConditionMatcherFactory) {
        self.conditionMatcherFactory = conditionMatcherFactory
    }

    func matches(target: Target, workspace: Workspace, user: HackleUser) throws -> Bool {
        try target.conditions.allSatisfy { it in
            try matches(condition: it, workspace: workspace, user: user)
        }
    }

    private func matches(condition: Target.Condition, workspace: Workspace, user: HackleUser) throws -> Bool {
        let conditionMatcher = conditionMatcherFactory.getMatcher(condition.key.type)
        return try conditionMatcher.matches(condition: condition, workspace: workspace, user: user)
    }
}

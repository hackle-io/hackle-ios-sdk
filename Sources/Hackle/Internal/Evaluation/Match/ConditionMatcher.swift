import Foundation

protocol ConditionMatcher {
    func matches(condition: Target.Condition, workspace: Workspace, user: HackleUser) -> Bool
}

protocol ConditionMatcherFactory {
    func getMatcher(_ type: Target.KeyType) -> ConditionMatcher
}

class PropertyConditionMatcher: ConditionMatcher {

    private let valueOperatorMatcher: ValueOperatorMatcher

    init(valueOperatorMatcher: ValueOperatorMatcher) {
        self.valueOperatorMatcher = valueOperatorMatcher
    }

    func matches(condition: Target.Condition, workspace: Workspace, user: HackleUser) -> Bool {
        guard let userValue = resolvePropertyOrNil(user: user, key: condition.key) else {
            return false
        }
        return valueOperatorMatcher.matches(userValue: userValue, match: condition.match)
    }

    private func resolvePropertyOrNil(user: HackleUser, key: Target.Key) -> Any? {
        switch key.type {
        case .userProperty: return user.properties?[key.name]
        case .hackleProperty: return user.hackleProperties?[key.name]
        }
    }
}

class DefaultConditionMatcherFactory: ConditionMatcherFactory {

    private let propertyConditionMatcher =
        PropertyConditionMatcher(
            valueOperatorMatcher: DefaultValueOperatorMatcher(
                valueMatcherFactory: ValueMatcherFactory(),
                operatorMatcherFactory: OperatorMatcherFactory()
            )
        )

    func getMatcher(_ type: Target.KeyType) -> ConditionMatcher {
        switch type {
        case .hackleProperty: return propertyConditionMatcher
        case .userProperty: return propertyConditionMatcher
        }
    }
}

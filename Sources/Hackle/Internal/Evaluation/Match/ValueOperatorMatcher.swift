import Foundation

protocol ValueOperatorMatcher {
    func matches(userValue: Any, match: Target.Match) -> Bool
}

class DefaultValueOperatorMatcher: ValueOperatorMatcher {

    private let valueMatcherFactory: ValueMatcherFactory
    private let operatorMatcherFactory: OperatorMatcherFactory

    init(valueMatcherFactory: ValueMatcherFactory, operatorMatcherFactory: OperatorMatcherFactory) {
        self.valueMatcherFactory = valueMatcherFactory
        self.operatorMatcherFactory = operatorMatcherFactory
    }

    func matches(userValue: Any, match: Target.Match) -> Bool {

        let valueMatcher = valueMatcherFactory.getMatcher(match.valueType)
        let operatorMatcher = operatorMatcherFactory.getMatcher(match.matchOperator)

        let isMatched = match.values.contains { it in
            valueMatcher.matches(operatorMatcher: operatorMatcher, userValue: userValue, matchValue: it)
        }

        return match.type.matches(isMatched)
    }
}

private extension Target.MatchType {
    func matches(_ isMatched: Bool) -> Bool {
        switch self {
        case .match: return isMatched
        case .notMatch: return !isMatched
        }
    }
}

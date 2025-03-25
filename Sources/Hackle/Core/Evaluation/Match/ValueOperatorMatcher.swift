import Foundation

protocol ValueOperatorMatcher {
    func matches(userValue: Any?, match: Target.Match) -> Bool
}

class DefaultValueOperatorMatcher: ValueOperatorMatcher {

    private let valueMatcherFactory: ValueMatcherFactory
    private let operatorMatcherFactory: OperatorMatcherFactory

    init(valueMatcherFactory: ValueMatcherFactory, operatorMatcherFactory: OperatorMatcherFactory) {
        self.valueMatcherFactory = valueMatcherFactory
        self.operatorMatcherFactory = operatorMatcherFactory
    }

    func matches(userValue: Any?, match: Target.Match) -> Bool {
        let valueMatcher = valueMatcherFactory.getMatcher(match.valueType)
        let operatorMatcher = operatorMatcherFactory.getMatcher(match.matchOperator)
        let isMatched = matches(userValue: userValue, match: match, valueMatcher: valueMatcher, operatorMatcher: operatorMatcher)
        return match.type.matches(isMatched)
    }

    private func matches(
        userValue: Any?,
        match: Target.Match,
        valueMatcher: ValueMatcher,
        operatorMatcher: OperatorMatcher
    ) -> Bool {
        if let userValues = userValue as? [Any?] {
            return arrayMatches(userValues: userValues, match: match, valueMatcher: valueMatcher, operatorMatcher: operatorMatcher)
        }
        return singleMatches(userValue: userValue, match: match, valueMatcher: valueMatcher, operatorMatcher: operatorMatcher)
    }

    private func singleMatches(
        userValue: Any?,
        match: Target.Match,
        valueMatcher: ValueMatcher,
        operatorMatcher: OperatorMatcher
    ) -> Bool {
        return operatorMatcher.matches(valueMatcher: valueMatcher, userValue: userValue, matchValues: match.values)
    }

    private func arrayMatches(
        userValues: [Any?],
        match: Target.Match,
        valueMatcher: ValueMatcher,
        operatorMatcher: OperatorMatcher
    ) -> Bool {
        userValues.contains { it in
            guard let userValue = it else {
                return false
            }
            return singleMatches(userValue: userValue, match: match, valueMatcher: valueMatcher, operatorMatcher: operatorMatcher)
        }
    }
}

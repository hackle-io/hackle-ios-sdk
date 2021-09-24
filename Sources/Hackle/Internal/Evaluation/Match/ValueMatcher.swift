import Foundation

protocol ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: MatchValue) -> Bool
}

class StringMatcher: ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: MatchValue) -> Bool {
        guard let userValue: String = Objects.asStringOrNil(userValue),
              let matchValue: String = matchValue.stringOrNil else {
            return false
        }
        return operatorMatcher.matches(userValue: userValue, matchValue: matchValue)
    }
}

class NumberMatcher: ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: MatchValue) -> Bool {
        guard let userValue: Double = Objects.asDoubleOrNil(userValue),
              let matchValue: Double = matchValue.numberOrNil else {
            return false
        }
        return operatorMatcher.matches(userValue: userValue, matchValue: matchValue)
    }

}

class BoolMatcher: ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: MatchValue) -> Bool {
        guard let userValue: Bool = Objects.asBoolOrNil(userValue),
              let matchValue: Bool = matchValue.boolOrNil else {
            return false
        }
        return operatorMatcher.matches(userValue: userValue, matchValue: matchValue)
    }
}

class ValueMatcherFactory {

    private let stringMatcher = StringMatcher()
    private let numberMatcher = NumberMatcher()
    private let boolMatcher = BoolMatcher()

    func getMatcher(_ valueType: Target.Match.ValueType) -> ValueMatcher {
        switch valueType {
        case .string: return stringMatcher
        case .number: return numberMatcher
        case .bool: return boolMatcher
        }
    }
}

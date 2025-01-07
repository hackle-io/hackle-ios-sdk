import Foundation

protocol ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: HackleValue) -> Bool
}

class StringMatcher: ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString() else {
            return false
        }
        return operatorMatcher.matches(userValue: userValue, matchValue: matchValue)
    }
}

class NumberMatcher: ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: Double = HackleValue(value: userValue).asDouble(),
              let matchValue: Double = matchValue.asDouble() else {
            return false
        }
        return operatorMatcher.matches(userValue: userValue, matchValue: matchValue)
    }
}

class BoolMatcher: ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: Bool = HackleValue(value: userValue).asBool(),
              let matchValue: Bool = matchValue.asBool() else {
            return false
        }
        return operatorMatcher.matches(userValue: userValue, matchValue: matchValue)
    }
}

class VersionMatcher: ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue = Version.tryParse(value: userValue),
              let matchValue = Version.tryParse(value: matchValue.stringOrNil) else {
            return false
        }
        return operatorMatcher.matches(userValue: userValue, matchValue: matchValue)
    }
}

class NoneMatcher: ValueMatcher {
    func matches(operatorMatcher: OperatorMatcher, userValue: Any, matchValue: HackleValue) -> Bool {
        false
    }
}

class ValueMatcherFactory {

    private let stringMatcher = StringMatcher()
    private let numberMatcher = NumberMatcher()
    private let boolMatcher = BoolMatcher()
    private let versionMatcher = VersionMatcher()
    private let noneMatcher = NoneMatcher()

    func getMatcher(_ valueType: HackleValueType) -> ValueMatcher {
        switch valueType {
        case .string: return stringMatcher
        case .number: return numberMatcher
        case .bool: return boolMatcher
        case .version: return versionMatcher
        case .json: return stringMatcher
        case .null: return noneMatcher
        }
    }
}

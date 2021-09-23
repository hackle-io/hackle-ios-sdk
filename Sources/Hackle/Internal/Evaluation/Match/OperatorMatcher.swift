import Foundation

protocol OperatorMatcher {
    func matches(userValue: String, matchValue: String) -> Bool
    func matches(userValue: Double, matchValue: Double) -> Bool
    func matches(userValue: Bool, matchValue: Bool) -> Bool
}

class InMatcher: OperatorMatcher {
    func matches(userValue: String, matchValue: String) -> Bool {
        userValue == matchValue
    }

    func matches(userValue: Double, matchValue: Double) -> Bool {
        userValue == matchValue
    }

    func matches(userValue: Bool, matchValue: Bool) -> Bool {
        userValue == matchValue
    }
}

class ContainsMatcher: OperatorMatcher {
    func matches(userValue: String, matchValue: String) -> Bool {
        userValue.contains(matchValue)
    }

    func matches(userValue: Double, matchValue: Double) -> Bool {
        false
    }

    func matches(userValue: Bool, matchValue: Bool) -> Bool {
        false
    }
}

class StartsWithMatcher: OperatorMatcher {
    func matches(userValue: String, matchValue: String) -> Bool {
        userValue.hasPrefix(matchValue)
    }

    func matches(userValue: Double, matchValue: Double) -> Bool {
        false
    }

    func matches(userValue: Bool, matchValue: Bool) -> Bool {
        false
    }
}

class EndsWithMatcher: OperatorMatcher {
    func matches(userValue: String, matchValue: String) -> Bool {
        userValue.hasSuffix(matchValue)
    }

    func matches(userValue: Double, matchValue: Double) -> Bool {
        false
    }

    func matches(userValue: Bool, matchValue: Bool) -> Bool {
        false
    }
}

class GreaterThanMatcher: OperatorMatcher {
    func matches(userValue: String, matchValue: String) -> Bool {
        false
    }

    func matches(userValue: Double, matchValue: Double) -> Bool {
        userValue > matchValue
    }

    func matches(userValue: Bool, matchValue: Bool) -> Bool {
        false
    }
}

class GreaterThanOrEqualToMatcher: OperatorMatcher {
    func matches(userValue: String, matchValue: String) -> Bool {
        false
    }

    func matches(userValue: Double, matchValue: Double) -> Bool {
        userValue >= matchValue
    }

    func matches(userValue: Bool, matchValue: Bool) -> Bool {
        false
    }
}

class LessThanMatcher: OperatorMatcher {
    func matches(userValue: String, matchValue: String) -> Bool {
        false
    }

    func matches(userValue: Double, matchValue: Double) -> Bool {
        userValue < matchValue
    }

    func matches(userValue: Bool, matchValue: Bool) -> Bool {
        false
    }
}

class LessThanOrEqualToMatcher: OperatorMatcher {
    func matches(userValue: String, matchValue: String) -> Bool {
        false
    }

    func matches(userValue: Double, matchValue: Double) -> Bool {
        userValue <= matchValue
    }

    func matches(userValue: Bool, matchValue: Bool) -> Bool {
        false
    }
}

class OperatorMatcherFactory {

    private let inMatcher = InMatcher()
    private let containsMatcher = ContainsMatcher()
    private let startsWithMatcher = StartsWithMatcher()
    private let endsWithMatcher = EndsWithMatcher()
    private let greaterThanMatcher = GreaterThanMatcher()
    private let greaterThanOrEqualToMatcher = GreaterThanOrEqualToMatcher()
    private let lessThanMatcher = LessThanMatcher()
    private let lessThanOrEqualToMatcher = LessThanOrEqualToMatcher()

    func getMatcher(_ matchOperator: Target.Match.Operator) -> OperatorMatcher {
        switch matchOperator {
        case ._in: return inMatcher
        case .contains: return containsMatcher
        case .startsWith: return startsWithMatcher
        case .endsWith: return endsWithMatcher
        case .gt: return greaterThanMatcher
        case .gte: return greaterThanOrEqualToMatcher
        case .lt: return lessThanMatcher
        case .lte: return lessThanOrEqualToMatcher
        }
    }
}

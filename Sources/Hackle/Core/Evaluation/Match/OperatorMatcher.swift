import Foundation

protocol OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool
}

class InMatcher: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        guard let userValue = userValue else {
            return false
        }
        
        return matchValues.contains { it in
            valueMatcher.inMatch(userValue: userValue, matchValue: it)
        }
    }
}

class ContainsMatcher: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        guard let userValue = userValue else {
            return false
        }
        
        return matchValues.contains { it in
            valueMatcher.containsMatch(userValue: userValue, matchValue: it)
        }
    }
}

class StartsWithMatcher: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        guard let userValue = userValue else {
            return false
        }
        
        return matchValues.contains { it in
            valueMatcher.startsWithMatch(userValue: userValue, matchValue: it)
        }
    }
}

class EndsWithMatcher: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        guard let userValue = userValue else {
            return false
        }
        
        return matchValues.contains { it in
            valueMatcher.endsWithMatch(userValue: userValue, matchValue: it)
        }
    }
}

class GreaterThanMatcher: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        guard let userValue = userValue else {
            return false
        }
        
        return matchValues.contains { it in
            valueMatcher.greaterThanMatch(userValue: userValue, matchValue: it)
        }
    }
}

class GreaterThanOrEqualToMatcher: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        guard let userValue = userValue else {
            return false
        }
        
        return matchValues.contains { it in
            valueMatcher.greaterThanOrEqualMatch(userValue: userValue, matchValue: it)
        }
    }
}

class LessThanMatcher: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        guard let userValue = userValue else {
            return false
        }
        
        return matchValues.contains { it in
            valueMatcher.lessThanMatch(userValue: userValue, matchValue: it)
        }
    }
}

class LessThanOrEqualToMatcher: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        guard let userValue = userValue else {
            return false
        }
        
        return matchValues.contains { it in
            valueMatcher.lessThanOrEqualMatch(userValue: userValue, matchValue: it)
        }
    }
}

class ExistsMatcher: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        userValue != nil
    }
}

class RegexMathcer: OperatorMatcher {
    func matches(valueMatcher: ValueMatcher, userValue: Any?, matchValues: [HackleValue]) -> Bool {
        guard let userValue = userValue as? String else {
            return false
        }
        
        return matchValues.contains { it in
            valueMatcher.regexMatch(userValue: userValue, matchValue: it)
        }
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
    private let existsMatcher = ExistsMatcher()
    private let regexMatcher = RegexMathcer()

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
        case .exists: return existsMatcher
        case .regex: return regexMatcher
        }
    }
}

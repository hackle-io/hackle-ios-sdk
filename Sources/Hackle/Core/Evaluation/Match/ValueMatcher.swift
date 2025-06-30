import Foundation

protocol ValueMatcher {
    func inMatch(userValue: Any, matchValue: HackleValue) -> Bool
    func containsMatch(userValue: Any, matchValue: HackleValue) -> Bool
    func startsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool
    func endsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool
    func greaterThanMatch(userValue: Any, matchValue: HackleValue) -> Bool
    func greaterThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool
    func lessThanMatch(userValue: Any, matchValue: HackleValue) -> Bool
    func lessThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool
    func regexMatch(userValue: Any, matchValue: HackleValue) -> Bool
}

class StringMatcher: ValueMatcher {
    func inMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString() else {
            return false
        }
        
        return userValue == matchValue
    }
    
    func containsMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString() else {
            return false
        }
        
        return userValue.contains(matchValue)
    }
    
    func startsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString() else {
            return false
        }
        
        return userValue.hasPrefix(matchValue)
    }
    
    func endsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString() else {
            return false
        }
        
        return userValue.hasSuffix(matchValue)
    }
    
    func greaterThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString() else {
            return false
        }
        
        return userValue > matchValue
    }
    
    func greaterThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString() else {
            return false
        }
        
        return userValue >= matchValue
    }
    
    func lessThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString() else {
            return false
        }
        
        return userValue < matchValue
    }
    
    func lessThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString() else {
            return false
        }
        
        return userValue <= matchValue
    }
    
    func regexMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: String = HackleValue(value: userValue).asString(),
              let matchValue: String = matchValue.asString(),
              let regex = try? NSRegularExpression(pattern: matchValue) else {
            return false
        }
        let range = NSRange(location: 0, length: userValue.utf16.count)
        
        return regex.firstMatch(in: userValue, range: range) != nil
    }
}

class NumberMatcher: ValueMatcher {
    func inMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: Double = HackleValue(value: userValue).asDouble(),
              let matchValue: Double = matchValue.asDouble() else {
            return false
        }
        
        return userValue == matchValue
    }
    
    func containsMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func startsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func endsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func greaterThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: Double = HackleValue(value: userValue).asDouble(),
              let matchValue: Double = matchValue.asDouble() else {
            return false
        }
        
        return userValue > matchValue
    }
    
    func greaterThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: Double = HackleValue(value: userValue).asDouble(),
              let matchValue: Double = matchValue.asDouble() else {
            return false
        }
        
        return userValue >= matchValue
    }
    
    func lessThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: Double = HackleValue(value: userValue).asDouble(),
              let matchValue: Double = matchValue.asDouble() else {
            return false
        }
        
        return userValue < matchValue
    }
    
    func lessThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: Double = HackleValue(value: userValue).asDouble(),
              let matchValue: Double = matchValue.asDouble() else {
            return false
        }
        
        return userValue <= matchValue
    }
    
    func regexMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
}

class BoolMatcher: ValueMatcher {
    func inMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue: Bool = HackleValue(value: userValue).asBool(),
              let matchValue: Bool = matchValue.asBool() else {
            return false
        }
        
        return userValue == matchValue
    }
    
    func containsMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func startsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func endsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func greaterThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func greaterThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func lessThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func lessThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func regexMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
}

class VersionMatcher: ValueMatcher {
    func inMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue = HackleValue(value: userValue).asVersion(),
              let matchValue = Version.tryParse(value: matchValue.stringOrNil) else {
            return false
        }
        
        return userValue == matchValue
    }
    
    func containsMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func startsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func endsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func greaterThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue = HackleValue(value: userValue).asVersion(),
              let matchValue = Version.tryParse(value: matchValue.stringOrNil) else {
            return false
        }
        
        return userValue > matchValue
    }
    
    func greaterThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue = HackleValue(value: userValue).asVersion(),
              let matchValue = Version.tryParse(value: matchValue.stringOrNil) else {
            return false
        }
        
        return userValue >= matchValue
    }
    
    func lessThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue = HackleValue(value: userValue).asVersion(),
              let matchValue = Version.tryParse(value: matchValue.stringOrNil) else {
            return false
        }
        
        return userValue < matchValue
    }
    
    func lessThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        guard let userValue = HackleValue(value: userValue).asVersion(),
              let matchValue = Version.tryParse(value: matchValue.stringOrNil) else {
            return false
        }
        
        return userValue <= matchValue
    }
    
    func regexMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
}

class NoneMatcher: ValueMatcher {
    func inMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func containsMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func startsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func endsWithMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func greaterThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func greaterThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func lessThanMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func lessThanOrEqualMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
    }
    
    func regexMatch(userValue: Any, matchValue: HackleValue) -> Bool {
        return false
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

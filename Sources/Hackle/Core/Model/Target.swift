import Foundation

class Target {

    var conditions: [Condition]

    init(conditions: [Condition]) {
        self.conditions = conditions
    }

    class Condition {
        var key: Key
        var match: Match

        init(key: Key, match: Match) {
            self.key = key
            self.match = match
        }
    }

    class Key {
        var type: KeyType
        var name: String

        init(type: KeyType, name: String) {
            self.type = type
            self.name = name
        }
    }

    enum KeyType: String, Codable {
        case userId = "USER_ID"
        case userProperty = "USER_PROPERTY"
        case hackleProperty = "HACKLE_PROPERTY"
        case eventProperty = "EVENT_PROPERTY"
        case segment = "SEGMENT"
        case abTest = "AB_TEST"
        case featureFlag = "FEATURE_FLAG"
        case cohort = "COHORT"
        case numberOfEventsInDays = "NUMBER_OF_EVENTS_IN_DAYS"
    }

    class Match: Codable {

        var type: MatchType
        var matchOperator: Operator
        var valueType: HackleValueType
        var values: [HackleValue]

        init(type: MatchType, matchOperator: Operator, valueType: HackleValueType, values: [HackleValue]) {
            self.type = type
            self.matchOperator = matchOperator
            self.valueType = valueType
            self.values = values
        }

        enum Operator: String, Codable {
            case _in = "IN"
            case contains = "CONTAINS"
            case startsWith = "STARTS_WITH"
            case endsWith = "ENDS_WITH"
            case gt = "GT"
            case gte = "GTE"
            case lt = "LT"
            case lte = "LTE"
        }
    }

    enum MatchType: String, Codable {
        case match = "MATCH"
        case notMatch = "NOT_MATCH"
    }
}

extension Target.MatchType {
    func matches(_ isMatched: Bool) -> Bool {
        switch self {
        case .match: return isMatched
        case .notMatch: return !isMatched
        }
    }
}

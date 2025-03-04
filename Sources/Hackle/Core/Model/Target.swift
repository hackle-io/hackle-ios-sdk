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
        case numberOfEventsWithPropertyInDays = "NUMBER_OF_EVENTS_WITH_PROPERTY_IN_DAYS"
    }

    class Match {

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

    /// 기간 동안 이벤트 발생 횟수
    class NumberOfEventsInDays: NumberOfEventInDay {
        /// 이벤트 키
        let eventKey: String
        /// 기간
        let days: Int
        
        init(eventKey: String, days: Int) {
            self.eventKey = eventKey
            self.days = days
        }
    }
    
    /// 기간 동안 프로퍼티를 포함한 이벤트 발생 횟수
    class NumberOfEventsWithPropertyInDays: NumberOfEventInDay {
        /// 이벤트 키
        let eventKey: String
        /// 기간
        let days: Int
        /// 추가 필터
        let propertyFilter: Condition
        
        init(eventKey: String, days: Int, propertyFilter: Condition) {
            self.eventKey = eventKey
            self.days = days
            self.propertyFilter = propertyFilter
        }
    }
}

protocol TargetSegmentationExpression {
    
}

protocol NumberOfEventInDay: TargetSegmentationExpression {
    /// 이벤트 키
    var eventKey: String { get }
    /// 기간
    var days: Int { get }
}

extension Target.MatchType {
    func matches(_ isMatched: Bool) -> Bool {
        switch self {
        case .match: return isMatched
        case .notMatch: return !isMatched
        }
    }
}

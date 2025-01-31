//
//  TargetEventConditionMatcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 1/31/25.
//

class TargetEventConditionMatcher: ConditionMatcher {
    let numberOfEventsInDaysMatcher: NumberOfEventsInDaysMatcher
    
    init(numberOfEventsInDaysMatcher: NumberOfEventsInDaysMatcher) {
        self.numberOfEventsInDaysMatcher = numberOfEventsInDaysMatcher
    }
    
    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        switch condition.key.type {
        case .numberOfEventsInDays:
            return try numberOfEventsInDaysMatcher.matches(targetEvents: request.user.targetEvents, condition: condition)
        case .userId, .userProperty, .hackleProperty, .eventProperty, .segment, .cohort, .abTest, .featureFlag:
            throw HackleError.error("Unsupported TargetKeyType [\(condition.key.type)]")
        }
    }
}

protocol TargetSegmentationExpressionMatcher {
    var valueOperatorMatcher: ValueOperatorMatcher { get }
    static var DEFAULT_PROPERTY_KEY: String { get }
    
    /// 조건에 만족하는 이벤트가 있는지 확인합니다.
    /// - Parameters:
    ///   - targetEvents: 비교 할 이벤트 목록
    ///   - condition: condition
    /// - Returns: 조건에 만족하는지 여부
    func matches(targetEvents: [TargetEvent], condition: Target.Condition) throws -> Bool
}

class NumberOfEventsInDaysMatcher: TargetSegmentationExpressionMatcher {
    var valueOperatorMatcher: ValueOperatorMatcher
    
    init(valueOperatorMatcher: ValueOperatorMatcher) {
        self.valueOperatorMatcher = valueOperatorMatcher
    }
    
    func matches(targetEvents: [TargetEvent], condition: Target.Condition) throws -> Bool {
        let numberOfEventsInDays = try condition.key.name.toNumberOfEventsInDays()
        let daysAgoUtc = SystemClock.shared.currentMillis() - SystemClock.shared.daysToMillis(days: numberOfEventsInDays.timeRange.periodDays)
        let filteredTargetEvents = targetEvents.filter { $0.eventKey == numberOfEventsInDays.eventKey }
        return match(filteredTargetEvents: filteredTargetEvents, daysAgoUtc: daysAgoUtc, condition: condition, filters: numberOfEventsInDays.filters)
    }
    
    /// 조건에 만족하는 이벤트가 있는지 확인합니다.
    ///
    /// filter가 있는 경우 모든 필터 조건을 만족해야 합니다.
    /// - Parameters:
    ///   - filteredTargetEvents: eventKey로 필터링된 이벤트 목록
    ///   - daysAgoUtc: event 발생 체크 할 시작 utc
    ///   - condition: condition
    ///   - filters: 추가로 체크 할 프로퍼티 필터
    /// - Returns: 조건에 만족하는지 여부
    private func match(
        filteredTargetEvents: [TargetEvent],
        daysAgoUtc: Int64,
        condition: Target.Condition,
        filters: [TargetSegmentationOption.PropertyFilter]?
    ) -> Bool {
        let targetEventMap = Dictionary(grouping: filteredTargetEvents) {
            $0.property?.key ?? Self.DEFAULT_PROPERTY_KEY
        }
        
        guard let filters = filters else {
            let targetEvent = targetEventMap[Self.DEFAULT_PROPERTY_KEY]
            return targetEvent?.contains { event in
                let eventCount = event.countWithinDays(daysAgoUtc: daysAgoUtc)
                return valueOperatorMatcher.matches(userValue: eventCount, match: condition.match)
            } ?? false
        }
        
        return filters.allSatisfy { propertyFilter in
            return targetEventMap[propertyFilter.propertyKey.name]?.contains { event in
                guard let property = event.property else {
                    return false
                }
                let eventCount = event.countWithinDays(daysAgoUtc: daysAgoUtc)
                return valueOperatorMatcher.matches(userValue: property.value, match: propertyFilter.match) && valueOperatorMatcher.matches(userValue: eventCount, match: condition.match)
            } ?? false
        }
    }
}

extension TargetSegmentationExpressionMatcher {
    static var DEFAULT_PROPERTY_KEY: String {
        "DEFAULT_HACKLE_PROPERTY"
    }
}

extension TargetEvent {
    func countWithinDays(daysAgoUtc: Int64) -> Int {
        return stats.filter { $0.date >= daysAgoUtc }.sumOf {
            $0.count
        }
    }
}

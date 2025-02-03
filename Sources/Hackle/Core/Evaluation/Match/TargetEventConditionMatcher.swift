//
//  TargetEventConditionMatcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 1/31/25.
//

class TargetEventConditionMatcher: ConditionMatcher {
    let numberOfEventsInDaysMatcher: NumberOfEventsInDaysMatcher
    let numberOfEventsWithPropertyInDaysMatcher: NumberOfEventsWithPropertyInDaysMatcher
    
    init(
        numberOfEventsInDaysMatcher: NumberOfEventsInDaysMatcher,
        numberOfEventsWithPropertyInDaysMatcher: NumberOfEventsWithPropertyInDaysMatcher) {
        self.numberOfEventsInDaysMatcher = numberOfEventsInDaysMatcher
        self.numberOfEventsWithPropertyInDaysMatcher = numberOfEventsWithPropertyInDaysMatcher
    }
    
    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        switch condition.key.type {
        case .numberOfEventsInDays:
            return try numberOfEventsInDaysMatcher.match(targetEvents: request.user.targetEvents, condition: condition)
        case .numberOfEventsWithPropertyInDays:
            return try numberOfEventsWithPropertyInDaysMatcher.match(targetEvents: request.user.targetEvents, condition: condition)
        case .userId, .userProperty, .hackleProperty, .eventProperty, .segment, .cohort, .abTest, .featureFlag:
            throw HackleError.error("Unsupported TargetKeyType [\(condition.key.type)]")
        }
    }
}

protocol TargetSegmentationExpressionMatcher {
    var valueOperatorMatcher: ValueOperatorMatcher { get }
    
    /// 조건에 만족하는 이벤트가 있는지 확인합니다.
    /// - Parameters:
    ///   - targetEvents: 비교 할 이벤트 목록
    ///   - condition: condition
    /// - Returns: 조건에 만족하는지 여부
    func match(targetEvents: [TargetEvent], condition: Target.Condition) throws -> Bool
}

class NumberOfEventsInDaysMatcher: TargetSegmentationExpressionMatcher {
    var valueOperatorMatcher: ValueOperatorMatcher
    
    init(valueOperatorMatcher: ValueOperatorMatcher) {
        self.valueOperatorMatcher = valueOperatorMatcher
    }
    
    func match(targetEvents: [TargetEvent], condition: Target.Condition) throws -> Bool {
        let numberOfEventsInDays = try condition.key.name.toNumberOfEventsInDays()
        let daysAgoUtc = SystemClock.shared.currentMillis() - numberOfEventsInDays.days.getDaysToMillis()
        // 이벤트 키에 프로퍼티 없는 targetEvent 는 1개 이하가 보장
        // 만족하는 이벤트가 하나도 없을 때 null 이벤트를 만들어서 이벤트 횟수 0으로 처리
        let filteredTargetEvent = targetEvents
            .filter { $0.eventKey == numberOfEventsInDays.eventKey }
            .first { $0.property == nil }
        let eventCount = filteredTargetEvent.countWithinDays(daysAgoUtc: daysAgoUtc)
        return valueOperatorMatcher.matches(userValue: eventCount, match: condition.match)
            
    }
}

class NumberOfEventsWithPropertyInDaysMatcher: TargetSegmentationExpressionMatcher {
    var valueOperatorMatcher: ValueOperatorMatcher
    
    init(valueOperatorMatcher: ValueOperatorMatcher) {
        self.valueOperatorMatcher = valueOperatorMatcher
    }
    
    func match(targetEvents: [TargetEvent], condition: Target.Condition) throws -> Bool {
        let numberOfEventsWithPropertyInDays = try condition.key.name.toNumberOfEventsWithPropertyInDays()
        let daysAgoUtc = SystemClock.shared.currentMillis() - numberOfEventsWithPropertyInDays.days.getDaysToMillis()
        var filteredTargetEvent: [TargetEvent?] = targetEvents
            .filter { $0.eventKey == numberOfEventsWithPropertyInDays.eventKey }
            .filter {
                guard let property = $0.property else {
                    return false
                }

                return propertyMatch(property: property, propertyCondition: numberOfEventsWithPropertyInDays.propertyFilter)
            }
        // 만약 만족하는 이벤트의 갯수가 조건의 갯수보다 적다면 null 이벤트를 추가하여 이벤트 횟수 0인 이벤트 추가
        if filteredTargetEvent.count < condition.match.values.count {
            filteredTargetEvent.append(nil)
        }
        
        return filteredTargetEvent
            .contains {
                let eventCount = $0.countWithinDays(daysAgoUtc: daysAgoUtc)
                return valueOperatorMatcher.matches(userValue: eventCount, match: condition.match)
            }
    }
    
    /// 프로퍼티 일치 여부를 확인합니다.
    /// - Parameters:
    ///   - property: 타겟 이벤트에 기록 된 프로퍼티
    ///   - propertyCondition: 조건 프로퍼티
    /// - Returns: 만족 여부
    func propertyMatch(property: TargetEvent.Property, propertyCondition: Target.Condition) -> Bool {
        if propertyCondition.key.name != property.key {
            return false
        }
        
        return valueOperatorMatcher.matches(userValue: property.value, match: propertyCondition.match)
    }
}

extension TargetEvent? {
    /// 기간 내 이벤트 발생 횟수
    ///
    /// null이면 0을 반환합니다.
    /// - Parameter daysAgoUtc: 시작 기간
    /// - Returns: 횟수
    func countWithinDays(daysAgoUtc: Int64) -> Int {
        return self?.stats.filter { $0.date >= daysAgoUtc }.sumOf {
            $0.count
        } ?? 0
    }
}

extension Int {
    func getDaysToMillis() -> Int64 {
        return TimeUnit.daysToUnit(days: Double(self), unit: .days).toInt64OrNil() ?? 0
    }
}

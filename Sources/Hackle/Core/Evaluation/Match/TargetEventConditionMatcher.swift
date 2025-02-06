//
//  TargetEventConditionMatcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 1/31/25.
//

import Foundation

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

/// Targeting Segmentation Expression Matcher
protocol TargetSegmentationExpressionMatcher {
    associatedtype TargetSegmentationExpression: Target.TargetSegmentationExpression
    
    var valueOperatorMatcher: ValueOperatorMatcher { get }
    var clock: Clock { get }
    
    /// Target.Key to TargetSegmentationExpression
    func toSegmentationExpression(key: String) throws -> TargetSegmentationExpression
}

/// NumberOfEvent InDay Matcher
///
/// NumberOfEventInDay타입의 TargetSegmentationExpression에 대한 Matcher입니다.
protocol NumberOfEventInDayMatcher: TargetSegmentationExpressionMatcher where TargetSegmentationExpression: Target.NumberOfEventInDay {
    /// 조건에 만족하는 이벤트가 있는지 확인합니다.
    func match(targetEvents: [TargetEvent], condition: Target.Condition) throws -> Bool
    
    /// TargetEvent와 NumberOfEventInDay에 해당하는 이벤트가 있는지 확인합니다.
    func match(targetEvent: TargetEvent, targetSegmentationExpression: TargetSegmentationExpression) -> Bool
}

/// NumberOfEventInDayMatcher
///
/// 기간 내 이벤트 발생 횟수를 확인합니다.
class NumberOfEventsInDaysMatcher: NumberOfEventInDayMatcher {
    typealias TargetSegmentationExpression = Target.NumberOfEventsInDays
    
    var valueOperatorMatcher: ValueOperatorMatcher
    var clock: Clock
    
    init(valueOperatorMatcher: ValueOperatorMatcher, clock: Clock) {
        self.valueOperatorMatcher = valueOperatorMatcher
        self.clock = clock
    }
    
    func match(targetEvent: TargetEvent, targetSegmentationExpression: TargetSegmentationExpression) -> Bool {
        return targetEvent.eventKey == targetSegmentationExpression.eventKey && targetEvent.property == nil
    }
    
    func toSegmentationExpression(key: String) throws -> TargetSegmentationExpression {
        let data = key.data(using: .utf8)!
        return try JSONDecoder().decode(TargetSegmentationExpression.self, from: data)
    }
}

/// NumberOfEventWithPropertyInDaysMatcher
///
/// 기간 내 프로퍼티 조건을 만족하는 이벤트 발생 횟수를 확인합니다.
class NumberOfEventsWithPropertyInDaysMatcher: NumberOfEventInDayMatcher {
    typealias TargetSegmentationExpression = Target.NumberOfEventsWithPropertyInDays
    
    var valueOperatorMatcher: ValueOperatorMatcher
    var clock: Clock
    
    init(valueOperatorMatcher: ValueOperatorMatcher, clock: Clock) {
        self.valueOperatorMatcher = valueOperatorMatcher
        self.clock = clock
    }
    
    func match(targetEvent: TargetEvent, targetSegmentationExpression: TargetSegmentationExpression) -> Bool {
        guard let property = targetEvent.property else {
            return false
        }
        
        return targetEvent.eventKey == targetSegmentationExpression.eventKey && propertyMatch(property: property, propertyCondition: targetSegmentationExpression.propertyFilter)
    }
    
    func toSegmentationExpression(key: String) throws -> TargetSegmentationExpression {
        let data = key.data(using: .utf8)!
        return try JSONDecoder().decode(TargetSegmentationExpression.self, from: data)
    }
    
    /// 프로퍼티 일치 여부를 확인합니다.
    /// - Parameters:
    ///   - property: 타겟 이벤트에 기록 된 프로퍼티
    ///   - propertyCondition: 조건 프로퍼티
    /// - Returns: 만족 여부
    private func propertyMatch(property: TargetEvent.Property, propertyCondition: Target.Condition) -> Bool {
        if property.type == propertyCondition.key.type && propertyCondition.key.name != property.key {
            return false
        }
        
        return valueOperatorMatcher.matches(userValue: property.value, match: propertyCondition.match)
    }
}

extension NumberOfEventInDayMatcher {
    func match(targetEvents: [TargetEvent], condition: Target.Condition) throws -> Bool {
        let targetEventSegmentation = try toSegmentationExpression(key: condition.key.name)
        let daysAgoUtc = clock.currentMillis() - (try targetEventSegmentation.days.getDaysToMilliseconds())
        let eventCount = targetEvents
            .filter { match(targetEvent: $0, targetSegmentationExpression: targetEventSegmentation)}
            .sumOf {$0.countWithinDays(daysAgoUtc: daysAgoUtc)}
        
        return valueOperatorMatcher.matches(userValue: eventCount, match: condition.match)
    }
}

extension TargetEvent {
    /// 기간 내 이벤트 발생 횟수
    ///
    /// null이면 0을 반환합니다.
    /// - Parameter daysAgoUtc: 시작 기간
    /// - Returns: 횟수
    fileprivate func countWithinDays(daysAgoUtc: Int64) -> Int {
        return self.stats.filter { $0.date > daysAgoUtc }.sumOf {
            $0.count
        }
    }
}

extension Int {
    /// 일을 밀리초로 변환합니다.
    func getDaysToMilliseconds() throws -> Int64 {
        guard let millis = TimeUnit.daysToUnit(days: Double(self), unit: .milliseconds).toInt64OrNil() else {
            throw HackleError.error("Invalid days [\(self)]")
        }
        return millis
    }
}

//
//  DefaultTargetEventMatchSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/4/25.
//

import Nimble
import Quick
@testable import Hackle
import Foundation

class TargetEventConditionMatchSpecs: QuickSpec {
    private let clock = TestClock()
    let valueOperatorMatcher = DefaultValueOperatorMatcher(
        valueMatcherFactory: ValueMatcherFactory(),
        operatorMatcherFactory: OperatorMatcherFactory()
    )

    override func spec() {
        beforeEach {
            self.clock.setKstTime(9)
        }
        
        let sut = TargetEventConditionMatcher(
            numberOfEventsInDaysMatcher: NumberOfEventsInDaysMatcher(valueOperatorMatcher: valueOperatorMatcher, clock: clock),
            numberOfEventsWithPropertyInDaysMatcher: NumberOfEventsWithPropertyInDaysMatcher(valueOperatorMatcher: valueOperatorMatcher, clock: clock)
        )
        
        it("when unsupported TargetKeyType, fail") {
            let request = experimentRequest()
            let condition = Target.Condition(
                key: Target.Key(type: .featureFlag, name: "purchase"),
                match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 1)])
            )
            expect { try sut.matches(request: request, context: Evaluators.context(), condition: condition) }.to(throwError(HackleError.error("Unsupported TargetKeyType [featureFlag]")))
        }
        
        it("when unsupport propertyType, fail") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: [], property: TargetEvent.Property(key: "purchase", type: .eventProperty, value: HackleValue(value: "1")))
            ]
            
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 7, filter: Target.Condition(
                    key: Target.Key(type: .hackleProperty, name: "purchase"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "1")])
                )),
                operator: .gte,
                valueType: .number,
                targetValue: 1,
                expected: false
            )
        }
        
        it("when target event is empty in 30 days, fail") {
            verify(
                targetEvents: [],
                key: try self.getKeyString(eventKey: "purchase", days: 30),
                operator: .gte,
                valueType: .number,
                targetValue: 1,
                expected: false
            )
        }
        
        it("when eventkey is not match, fail") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: self.makeSingleTargetEventStat(daysAgo: 1), property: nil)
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "view", days: 30),
                operator: .gte,
                valueType: .number,
                targetValue: 1,
                expected: false
            )
        }
        
        it("when purchase event occur 1 every 30 days and match condition is purchase event in 30 days and target value is 1, success") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: self.makeTargetEventStat(daysAgo: 30), property: nil)
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 30),
                operator: .gte,
                valueType: .number,
                targetValue: 1,
                expected: true
            )
        }
        
        it("when login event occur 3 today and match condition is login event in 1 day and target value is 3, success") {
            let targetEvents = [
                TargetEvent(eventKey: "login", stats: self.makeSingleTargetEventStat(daysAgo: 0, count: 3), property: nil)
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "login", days: 1),
                operator: .gte,
                valueType: .number,
                targetValue: 3,
                expected: true
            )
        }
        
        it("when login event occur 3 yesterday and match condition is login event in 1 day and target value is 3 at today 8:00, success") {
            self.clock.setKstTime(8)
            let targetEvents = [
                TargetEvent(eventKey: "login", stats: self.makeSingleTargetEventStat(daysAgo: 0, count: 3), property: nil),
                TargetEvent(eventKey: "prucase", stats: self.makeTargetEventStat(daysAgo: 0, count: 3), property: nil)
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "login", days: 1),
                operator: ._in,
                valueType: .number,
                targetValue: 3,
                expected: true
            )
        }
        
        it("when login event occur 3 yesterday and match condition is login event in 1 day and target value is 3 at today 14:00, fail") {
            self.clock.setKstTime(14)
            let targetEvents = [
                TargetEvent(eventKey: "login", stats: self.makeSingleTargetEventStat(daysAgo: 1, count: 3), property: nil),
                TargetEvent(eventKey: "prucase", stats: self.makeSingleTargetEventStat(daysAgo: 1, count: 3), property: nil)
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "login", days: 1),
                operator: ._in,
                valueType: .number,
                targetValue: 3,
                expected: false
            )
        }
        
        it("when purchase event occur 3 every 30 days and match condition is purchase 100, fail") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: self.makeTargetEventStat(daysAgo: 30, count: 3), property: nil)
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 30),
                operator: ._in,
                valueType: .number,
                targetValue: 100,
                expected: false
            )
        }
        
        it("when purchase event with milk property occur 1 at 5 days ago and match condition is purchase event with milk property in 7 days and target value is 1, success") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: self.makeSingleTargetEventStat(daysAgo: 5), property: TargetEvent.Property(key: "product", type: .eventProperty, value: HackleValue(value: "milk")))
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 7, filter: Target.Condition(
                    key: Target.Key(type: .eventProperty, name: "product"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "milk")])
                )),
                operator: ._in,
                valueType: .number,
                targetValue: 1,
                expected: true
            )
        }
        
        it("when purchase event with milk property occur 1 at 5 days ago and match condition is purchase event with milk property in 7 days and target value is grater then 1, fail") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: self.makeSingleTargetEventStat(daysAgo: 5), property: TargetEvent.Property(key: "product", type: .eventProperty, value: HackleValue(value: "milk")))
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 7, filter: Target.Condition(
                    key: Target.Key(type: .eventProperty, name: "product"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "milk")])
                )),
                operator: .gt,
                valueType: .number,
                targetValue: 1,
                expected: false
            )
        }
        
        it("when purchase events with milk(1/day) and cookie(2/day) occur within 5 days, and filter contains milk/cookie then success") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: self.makeTargetEventStat(daysAgo: 1, count: 1), property: TargetEvent.Property(key: "productName", type: .eventProperty, value: HackleValue(value: "milk"))),
                TargetEvent(eventKey: "purchase", stats: self.makeTargetEventStat(daysAgo: 2, count: 2), property: TargetEvent.Property(key: "productName", type: .eventProperty, value: HackleValue(value: "cookie"))),
                TargetEvent(eventKey: "login", stats: self.makeTargetEventStat(daysAgo: 3, count: 3), property: nil),
                TargetEvent(eventKey: "purchase", stats: self.makeTargetEventStat(daysAgo: 3, count: 3), property: nil)
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 5, filter: Target.Condition(
                    key: Target.Key(type: .eventProperty, name: "productName"),
                    match: Target.Match(type: .match, matchOperator: .contains, valueType: .string, values: [HackleValue(value: "cookie"), HackleValue(value: "milk")])
                )),
                operator: .gte,
                valueType: .number,
                targetValue: 5,
                expected: true
            )
        }

        it("when purchase events with milk(7 days ago) and cookie(2 days) occur within 8 days, and filter contains milk/cookie then success") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: self.makeSingleTargetEventStat(daysAgo: 7, count: 1), property: TargetEvent.Property(key: "productName", type: .eventProperty, value: HackleValue(value: "milk"))),
                TargetEvent(eventKey: "purchase", stats: self.makeTargetEventStat(daysAgo: 2, count: 2), property: TargetEvent.Property(key: "productName", type: .eventProperty, value: HackleValue(value: "cookie")))
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 8, filter: Target.Condition(
                    key: Target.Key(type: .eventProperty, name: "productName"),
                    match: Target.Match(type: .match, matchOperator: .contains, valueType: .string, values: [HackleValue(value: "cookie"), HackleValue(value: "milk")])
                )),
                operator: ._in,
                valueType: .number,
                targetValue: 5,
                expected: true
            )
        }

        it("when events have properties but filter is empty then fail") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: self.makeTargetEventStat(daysAgo: 30, count: 1), property: TargetEvent.Property(key: "productName", type: .eventProperty, value: HackleValue(value: "milk")))
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 3),
                operator: .gte,
                valueType: .number,
                targetValue: 1,
                expected: false
            )
        }

        it("when no events occurred and target is 0 then success") {
            let targetEvents: [TargetEvent] = []
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 1),
                operator: .gte,
                valueType: .number,
                targetValue: 0,
                expected: true
            )
            
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 1, filter: Target.Condition(
                    key: Target.Key(type: .eventProperty, name: "productName"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "milk")])
                )),
                operator: .gte,
                valueType: .number,
                targetValue: 0,
                expected: true
            )
        }

        it("when partial matching events occurred and meet condition then success") {
            let targetEvents = [
                TargetEvent(eventKey: "purchase", stats: self.makeSingleTargetEventStat(daysAgo: 1, count: 3), property: TargetEvent.Property(key: "productName", type: .eventProperty, value: HackleValue(value: "cookie"))),
                TargetEvent(eventKey: "purchase", stats: self.makeSingleTargetEventStat(daysAgo: 0, count: 1), property: nil)
            ]
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(eventKey: "purchase", days: 7, filter: Target.Condition(
                    key: Target.Key(type: .eventProperty, name: "productName"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "milk"), HackleValue(value: "cookie")])
                )),
                operator: .gte,
                valueType: .number,
                targetValue: 1,
                expected: true
            )
        }
        
        it("when partial matching events occurred and meet condition then success") {
            let targetEvents = [
                TargetEvent(
                    eventKey: "purchase",
                    stats: self.makeSingleTargetEventStat(daysAgo: 1, count: 3),
                    property: TargetEvent.Property(
                        key: "productName",
                        type: .eventProperty,
                        value: HackleValue(value: "smartphone")
                    )
                ),
                TargetEvent(
                    eventKey: "purchase",
                    stats: self.makeSingleTargetEventStat(daysAgo: 0, count: 1),
                    property: nil
                )
            ]
            
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(
                    eventKey: "login",
                    days: 1
                ),
                operator: .gte,
                valueType: .number,
                targetValue: 0,
                expected: true
            )
            
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(
                    eventKey: "purchase",
                    days: 1,
                    filter: Target.Condition(
                        key: Target.Key(type: .eventProperty, name: "price"),
                        match: Target.Match(
                            type: .match,
                            matchOperator: .gte,
                            valueType: .number,
                            values: [HackleValue(value: 10000)]
                        )
                    )
                ),
                operator: .gte,
                valueType: .number,
                targetValue: 0,
                expected: true
            )
        }
        
        it("발생 조건에 부합하는 이벤트만 발생했지만 부합조건이 0이면 실패") {
            let targetEvents = [
                TargetEvent(
                    eventKey: "purchase",
                    stats: self.makeSingleTargetEventStat(daysAgo: 1, count: 3),
                    property: TargetEvent.Property(
                        key: "productName",
                        type: .eventProperty,
                        value: HackleValue(value: "cookie")
                    )
                ),
                TargetEvent(
                    eventKey: "purchase",
                    stats: self.makeSingleTargetEventStat(daysAgo: 0, count: 1),
                    property: TargetEvent.Property(
                        key: "productName",
                        type: .eventProperty,
                        value: HackleValue(value: "milk")
                    )
                ),
                TargetEvent(
                    eventKey: "purchase",
                    stats: self.makeSingleTargetEventStat(daysAgo: 0, count: 1),
                    property: nil
                )
            ]
            
            verify(
                targetEvents: targetEvents,
                key: try self.getKeyString(
                    eventKey: "purchase",
                    days: 7,
                    filter: Target.Condition(
                        key: Target.Key(type: .eventProperty, name: "productName"),
                        match: Target.Match(
                            type: .match,
                            matchOperator: ._in,
                            valueType: .string,
                            values: [HackleValue(value: "milk"), HackleValue(value: "cookie")]
                        )
                    )
                ),
                operator: ._in,
                valueType: .number,
                targetValue: 0,
                expected: false
            )
        }
        
        /// Verify test
        /// - Parameters:
        ///  - targetEvents: target events
        ///  - key: key
        ///  - operator: operator
        ///  - valueType: value type
        ///  - targetValue: target value
        ///  - expected: expected
        func verify(targetEvents: [TargetEvent], key: String, operator: Target.Match.Operator, valueType: HackleValueType, targetValue: Any, expected: Bool) {
            let request = experimentRequest(
                user: HackleUser.builder()
                    .targetEvents(targetEvents)
                    .build()
            )
            let keyType = if key.contains("propertyFilter") {
                Target.KeyType.numberOfEventsWithPropertyInDays
            } else {
                Target.KeyType.numberOfEventsInDays
            }

            let condition = Target.Condition(
                key: Target.Key(type: keyType, name: key),
                match: Target.Match(type: .match, matchOperator: `operator`, valueType: valueType, values: [HackleValue(value: targetValue)])
            )
            
            expect { try sut.matches(request: request, context: Evaluators.context(), condition: condition) }.to(equal(expected))
        }
    }

    /// NumberOfEventsInDays Json String
    /// - Parameters:
    ///   - eventKey: event key
    ///   - days: period
    /// - Returns: json string
    private func getKeyString(eventKey: String, days: Int) throws -> String {
        let model = Target.NumberOfEventsInDays(eventKey: eventKey, days: days)
        guard let data = try? JSONEncoder().encode(model),
              let jsonString = String(data: data, encoding: .utf8) else {
            throw HackleError.error("Failed to encode NumberOfEventsInDays model")
        }
        return jsonString
    }
    
    /// NumberOfEventsWithPropertyInDays Json String
    /// - Parameters:
    ///  - eventKey: event key
    ///  - days: period
    ///  - filter: property filter
    ///  - Returns: json string
    private func getKeyString(eventKey: String, days: Int, filter: Target.Condition) throws -> String {
        let model = Target.NumberOfEventsWithPropertyInDays(eventKey: eventKey, days: days, propertyFilter: filter)
        guard let data = try? JSONEncoder().encode(model),
              let jsonString = String(data: data, encoding: .utf8) else {
            throw HackleError.error("Failed to encode NumberOfEventsWithPropertyInDays model")
        }
        return jsonString
    }
    
    /// Create TargetEvent.Stat array
    /// - Parameters:
    ///  - days: period
    ///  - numOfEventsInDay: number of events in a day
    ///  - Returns: TargetEvent.Stat array
    private func makeTargetEventStat(daysAgo: Int, count: Int = 1) -> [TargetEvent.Stat] {
        let stats = (0..<daysAgo).map { day in
            TargetEvent.Stat(date: getTimeStamp(daysAgo: day), count: count)
        }
        
        return stats
    }
    
    /// Create TargetEvent.Stat for single day
    /// - Parameters:
    /// - day: target ago day
    /// - numOfEventsInDay: number of events in a day
    /// - Returns: TargetEvent.Stat array
    private func makeSingleTargetEventStat(daysAgo: Int, count: Int = 1) -> [TargetEvent.Stat] {
        return [
            TargetEvent.Stat(date: getTimeStamp(daysAgo: daysAgo), count: count)
        ]
    }
    
    /// Get TimeStamp
    /// - Parameters:
    /// - daysAgo: target ago day
    /// - Returns: timestamp
    private func getTimeStamp(daysAgo: Int) -> Int64 {
        let currentMills = self.clock.currentMillis()
        let daysAgoMillis = (try? daysAgo.getDaysToMilliseconds()) ?? 0
        let timeStamp = currentMills - (currentMills % (24 * 60 * 60 * 1000)) - daysAgoMillis
        return timeStamp
    }
    
    /// 오늘 기준으로 특정 KST의 UTC+0 timestampe를 반환하는 Clock
    private class TestClock: Clock {
        var kstTime: Int = 9
        private let kstOffset = TimeInterval(9 * 60 * 60 * 1000)
        
        func now() -> Date {
            let now = Date()
            let components = kstCalendar.dateComponents([.year, .month, .day], from: now)
            var targetComponents = DateComponents()
            targetComponents.year = components.year
            targetComponents.month = components.month
            targetComponents.day = components.day
            targetComponents.hour = kstTime
            return kstCalendar.date(from: targetComponents)!
        }
        
        func currentMillis() -> Int64 {
            now().epochMillis
        }
        
        func tick() -> UInt64 {
            UInt64(now().timeIntervalSince1970 * 1000 * 1000 * 1000)
        }
        
        func setKstTime(_ kstTime: Int) {
            guard (0...23).contains(kstTime) else {
                fatalError("Invalid KST time: \(kstTime)")
            }
            self.kstTime = kstTime
        }
        
        private let kstCalendar: Calendar = {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
            return cal
        }()
    }
}

#if hasAttribute(retroactive)
extension Target.NumberOfEventsInDays: @retroactive Encodable {
    private enum CodingKeys: String, CodingKey {
        case eventKey, days
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventKey, forKey: .eventKey)
        try container.encode(days, forKey: .days)
    }
}

extension Target.NumberOfEventsWithPropertyInDays: @retroactive Encodable {
    private enum CodingKeys: String, CodingKey {
        case eventKey, days, propertyFilter
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventKey, forKey: .eventKey)
        try container.encode(days, forKey: .days)
        try container.encode(propertyFilter, forKey: .propertyFilter)
    }
}

extension Target.Condition: @retroactive Encodable {
    private enum CodingKeys: String, CodingKey {
        case key, match
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(match, forKey: .match)
    }
}

extension Target.Key: @retroactive Encodable {
    private enum CodingKeys: String, CodingKey {
        case type, name
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
    }
}

extension Target.Match: @retroactive Encodable {
    private enum CodingKeys: String, CodingKey {
        case type, valueType, values
        case matchOperator = "operator"
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(matchOperator, forKey: .matchOperator)
        try container.encode(valueType, forKey: .valueType)
        try container.encode(values, forKey: .values)
    }
}
#else
extension Target.NumberOfEventsInDays: Encodable {
    private enum CodingKeys: String, CodingKey {
        case eventKey, days
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventKey, forKey: .eventKey)
        try container.encode(days, forKey: .days)
    }
}

extension Target.NumberOfEventsWithPropertyInDays: Encodable {
    private enum CodingKeys: String, CodingKey {
        case eventKey, days, propertyFilter
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventKey, forKey: .eventKey)
        try container.encode(days, forKey: .days)
        try container.encode(propertyFilter, forKey: .propertyFilter)
    }
}

extension Target.Condition: Encodable {
    private enum CodingKeys: String, CodingKey {
        case key, match
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(match, forKey: .match)
    }
}

extension Target.Key: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type, name
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
    }
}

extension Target.Match: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type, valueType, values
        case matchOperator = "operator"
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(matchOperator, forKey: .matchOperator)
        try container.encode(valueType, forKey: .valueType)
        try container.encode(values, forKey: .values)
    }
}
#endif

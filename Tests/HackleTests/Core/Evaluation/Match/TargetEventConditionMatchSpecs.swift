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
    override func spec() {
        let valueOperatorMatcher = DefaultValueOperatorMatcher(
            valueMatcherFactory: ValueMatcherFactory(),
            operatorMatcherFactory: OperatorMatcherFactory()
        )
        
        let clock = SystemClock.shared

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
    
    private func getKeyString(eventKey: String, days: Int) throws -> String {
        let model = Target.NumberOfEventsInDays(eventKey: eventKey, days: days)
        guard let data = try? JSONEncoder().encode(model),
              let jsonString = String(data: data, encoding: .utf8) else {
            throw HackleError.error("Failed to encode NumberOfEventsInDays model")
        }
        return jsonString
    }
    
    private func getKeyString(eventKey: String, days: Int, filter: Target.Condition) throws -> String {
        let model = Target.NumberOfEventsWithPropertyInDays(eventKey: eventKey, days: days, propertyFilter: filter)
        guard let data = try? JSONEncoder().encode(model),
              let jsonString = String(data: data, encoding: .utf8) else {
            throw HackleError.error("Failed to encode NumberOfEventsWithPropertyInDays model")
        }
        return jsonString
    }
    
}

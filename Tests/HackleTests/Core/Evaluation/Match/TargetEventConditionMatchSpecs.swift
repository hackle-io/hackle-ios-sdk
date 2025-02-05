//
//  DefaultTargetEventMatchSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/4/25.
//

import Nimble
import Quick
@testable import Hackle

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

        it("unsupported TargetKeyType") {
            let request = experimentRequest()
            let condition = Target.Condition(
                key: Target.Key(type: .featureFlag, name: "purchase"),
                match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 1)])
            )
            expect { try sut.matches(request: request, context: Evaluators.context(), condition: condition) }.to(throwError(HackleError.error("Unsupported TargetKeyType [featureFlag]")))
        }
    }
}

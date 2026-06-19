import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageDebugInspectorSpecs: QuickSpec {
    override class func spec() {

        func inspector() -> InAppMessageDebugInspector {
            InAppMessageDebugInspector(
                impressionStorage: DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()),
                hiddenStorage: DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository()),
                valueOperatorMatcher: DefaultValueOperatorMatcher(
                    valueMatcherFactory: ValueMatcherFactory(),
                    operatorMatcherFactory: OperatorMatcherFactory()
                ),
                userValueResolver: DefaultUserValueResolver()
            )
        }

        describe("targetDetails") {
            it("user property 조건 - 매칭되면 isMatched=true, 유저 값 노출") {
                let user = HackleUser.builder().property("age", 25).build()
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "age"),
                    match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 20)])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [Target(conditions: [condition])])
                )

                let groups = inspector().targetDetails(inAppMessage: inAppMessage, user: user)

                expect(groups.count) == 1
                expect(groups[0].index) == 1
                expect(groups[0].conditions.count) == 1
                let c = groups[0].conditions[0]
                expect(c.keyType) == "USER_PROPERTY"
                expect(c.keyName) == "age"
                expect(c.isUserProperty) == true
                expect(c.isMatched) == true
                expect(c.userValue) == "25"
            }

            it("user property 조건 - 비매칭되면 isMatched=false") {
                let user = HackleUser.builder().property("age", 15).build()
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "age"),
                    match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 20)])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [Target(conditions: [condition])])
                )

                let c = inspector().targetDetails(inAppMessage: inAppMessage, user: user)[0].conditions[0]

                expect(c.isMatched) == false
            }

            it("user property 값이 없으면 userValue=nil, isMatched=false") {
                let user = HackleUser.builder().build()
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "age"),
                    match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 20)])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [Target(conditions: [condition])])
                )

                let c = inspector().targetDetails(inAppMessage: inAppMessage, user: user)[0].conditions[0]

                expect(c.userValue).to(beNil())
                expect(c.isMatched) == false
            }

            it("user property가 아닌 조건(SEGMENT)은 userValue/isMatched가 nil") {
                let user = HackleUser.builder().build()
                let condition = Target.Condition(
                    key: Target.Key(type: .segment, name: "seg1"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "x")])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [Target(conditions: [condition])])
                )

                let c = inspector().targetDetails(inAppMessage: inAppMessage, user: user)[0].conditions[0]

                expect(c.keyType) == "SEGMENT"
                expect(c.isUserProperty) == false
                expect(c.userValue).to(beNil())
                expect(c.isMatched).to(beNil())
            }

            it("targets가 여러 개면 그룹 index가 1부터 증가") {
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "age"),
                    match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 20)])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [
                        Target(conditions: [condition]),
                        Target(conditions: [condition])
                    ])
                )

                let groups = inspector().targetDetails(inAppMessage: inAppMessage, user: HackleUser.builder().build())

                expect(groups.map { $0.index }) == [1, 2]
            }
        }
    }
}

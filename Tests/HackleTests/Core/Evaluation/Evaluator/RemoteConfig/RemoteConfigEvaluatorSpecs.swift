//
//  RemoteConfigEvaluatorSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class RemoteConfigEvaluatorSpecs: QuickSpec {

    override func spec() {

        var remoteConfigTargetRuleDeterminer: MockRemoteConfigTargetRuleDeterminer!
        var sut: RemoteConfigEvaluator!

        beforeEach {
            remoteConfigTargetRuleDeterminer = MockRemoteConfigTargetRuleDeterminer()
            sut = RemoteConfigEvaluator(remoteConfigTargetRuleDeterminer: remoteConfigTargetRuleDeterminer)

            every(remoteConfigTargetRuleDeterminer.determineTargetRuleOrNilMock).returns(nil)
        }

        it("supports") {
            expect(sut.support(request: experimentRequest())) == false
            expect(sut.support(request: remoteConfigRequest())) == true
        }

        describe("evaluate") {

            func parameter(
                id: Int64 = 42,
                key: String = "test_parameter_key",
                type: HackleValueType,
                identifierType: String = "$id",
                targetRules: [RemoteConfigParameter.TargetRule] = [],
                defaultValue: RemoteConfigParameter.Value
            ) -> RemoteConfigParameter {
                RemoteConfigParameter(id: id, key: key, type: type, identifierType: identifierType, targetRules: targetRules, defaultValue: defaultValue)
            }

            it("식별자가 없는 경우") {
                // given
                let parameter = parameter(
                    type: .string,
                    identifierType: "customId",
                    defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: HackleValue.string("hello value"))
                )

                let request = remoteConfigRequest(parameter: parameter)

                // when
                let actual: RemoteConfigEvaluation = try sut.evaluate(request: request, context: Evaluators.context())

                // then
                expect(actual.valueId).to(beNil())
                expect(actual.value) == HackleValue.string("default")
                expect(actual.reason) == DecisionReason.IDENTIFIER_NOT_FOUND
                expect(actual.properties["requestValueType"] as? String) == "STRING"
                expect(actual.properties["requestDefaultValue"] as? String) == "default"
                expect(actual.properties["returnValue"] as? String) == "default"
            }

            it("TargetRule 에 해당하는 경우") {
                // given
                let targetRule = RemoteConfigParameter.TargetRule(
                    key: "target_rule_key",
                    name: "target_rule_name",
                    target: Target(conditions: []),
                    bucketId: 42,
                    value: RemoteConfigParameter.Value(id: 320, rawValue: HackleValue.string("targetRuleValue"))
                )
                let parameter = parameter(
                    type: .string,
                    targetRules: [targetRule],
                    defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: HackleValue.string("hello value"))
                )

                every(remoteConfigTargetRuleDeterminer.determineTargetRuleOrNilMock).returns(targetRule)

                let request = remoteConfigRequest(parameter: parameter)

                // when
                let actual: RemoteConfigEvaluation = try sut.evaluate(request: request, context: Evaluators.context())

                // then
                expect(actual.valueId) == 320
                expect(actual.value) == HackleValue.string("targetRuleValue")
                expect(actual.reason) == DecisionReason.TARGET_RULE_MATCH
                expect(actual.properties["requestValueType"] as? String) == "STRING"
                expect(actual.properties["requestDefaultValue"] as? String) == "default"
                expect(actual.properties["returnValue"] as? String) == "targetRuleValue"
                expect(actual.properties["targetRuleKey"] as? String) == "target_rule_key"
                expect(actual.properties["targetRuleName"] as? String) == "target_rule_name"
            }

            it("TargetRule 에 매치되지 않는 경우") {
                // given
                let targetRule = RemoteConfigParameter.TargetRule(
                    key: "target_rule_key",
                    name: "target_rule_name",
                    target: Target(conditions: []),
                    bucketId: 42,
                    value: RemoteConfigParameter.Value(id: 320, rawValue: HackleValue.string("targetRuleValue"))
                )
                let parameter = parameter(
                    type: .string,
                    targetRules: [targetRule],
                    defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: HackleValue.string("hello value"))
                )

                every(remoteConfigTargetRuleDeterminer.determineTargetRuleOrNilMock).returns(nil)

                let request = remoteConfigRequest(parameter: parameter)

                // when
                let actual: RemoteConfigEvaluation = try sut.evaluate(request: request, context: Evaluators.context())

                // then
                expect(actual.valueId) == 43
                expect(actual.value) == HackleValue.string("hello value")
                expect(actual.reason) == DecisionReason.DEFAULT_RULE
                expect(actual.properties["requestValueType"] as? String) == "STRING"
                expect(actual.properties["requestDefaultValue"] as? String) == "default"
                expect(actual.properties["returnValue"] as? String) == "hello value"
            }

            it("type match") {
                try verifyMatch(HackleValue.string("match string"), HackleValue.string("default string"), true)
                try verifyMatch(HackleValue.string(""), HackleValue.string("default string"), true)
                try verifyMatch(HackleValue.double(0), HackleValue.string("default string"), false)
                try verifyMatch(HackleValue.double(1), HackleValue.string("default string"), false)
                try verifyMatch(HackleValue.bool(false), HackleValue.string("default string"), false)
                try verifyMatch(HackleValue.bool(true), HackleValue.string("default string"), false)

                try verifyMatch(HackleValue.double(0), HackleValue.double(999), true)
                try verifyMatch(HackleValue.double(1), HackleValue.double(999), true)
                try verifyMatch(HackleValue.double(-1), HackleValue.double(999), true)
                try verifyMatch(HackleValue.double(0.0), HackleValue.double(999), true)
                try verifyMatch(HackleValue.double(1.0), HackleValue.double(999), true)
                try verifyMatch(HackleValue.double(-1.0), HackleValue.double(999), true)
                try verifyMatch(HackleValue.double(1.1), HackleValue.double(999), true)
                try verifyMatch(HackleValue.string("1"), HackleValue.double(999), false)
                try verifyMatch(HackleValue.string("0"), HackleValue.double(999), false)
                try verifyMatch(HackleValue.bool(true), HackleValue.double(999), false)
                try verifyMatch(HackleValue.bool(false), HackleValue.double(999), false)

                try verifyMatch(HackleValue.bool(true), HackleValue.bool(false), true)
                try verifyMatch(HackleValue.bool(false), HackleValue.bool(true), true)
                try verifyMatch(HackleValue.double(0), HackleValue.bool(true), false)
                try verifyMatch(HackleValue.double(1), HackleValue.bool(false), false)
            }

            func verifyMatch(_ v1: HackleValue, _ v2: HackleValue, _ isMatch: Bool) throws {
                let parameter = parameter(type: .string, defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: v1))
                every(remoteConfigTargetRuleDeterminer.determineTargetRuleOrNilMock).returns(nil)

                let request = remoteConfigRequest(parameter: parameter, defaultValue: v2)

                let actual: RemoteConfigEvaluation = try sut.evaluate(request: request, context: Evaluators.context())

                if isMatch {
                    expect(actual.valueId) == 43
                    expect(actual.value) == v1
                    expect(actual.reason) == DecisionReason.DEFAULT_RULE
                } else {
                    expect(actual.valueId).to(beNil())
                    expect(actual.value) == v2
                    expect(actual.reason) == DecisionReason.TYPE_MISMATCH
                }
            }
        }
    }
}

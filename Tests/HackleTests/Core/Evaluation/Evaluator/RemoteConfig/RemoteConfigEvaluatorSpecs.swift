//
//  RemoteConfigEvaluatorSpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class RemoteConfigEvaluatorSpecs: QuickSpec {

    class TargetRuleMatcherStub: RemoteConfigParameterTargetRuleMatcher {
        var matchedRule: RemoteConfigParameter.TargetRule?

        init() {
            super.init(targetMatcher: MockTargetMatcher(), bucketer: MockBucketer())
        }

        override func matches(request: RemoteConfigLocalEvaluateRequest, context: EvaluatorContext, rule: RemoteConfigParameter.TargetRule) throws -> Bool {
            rule === matchedRule
        }
    }

    override class func spec() {

        var matcher: TargetRuleMatcherStub!
        var sut: RemoteConfigLocalEvaluator!

        beforeEach {
            matcher = TargetRuleMatcherStub()
            sut = RemoteConfigLocalEvaluator(
                targetRuleDeterminer: RemoteConfigParameterTargetRuleDeterminer(matcher: matcher),
                eventRecorder: MockEvaluationEventRecorder()
            )
        }

        it("supports") {
            expect(sut.supports(request: experimentRequest())) == false
            expect(sut.supports(request: remoteConfigRequest())) == true
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
                let response: RemoteConfigEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())
                let actual = response.remoteConfigEvaluation

                // then
                expect(actual.remoteConfigResult.valueId).to(beNil())
                expect(actual.remoteConfigResult.value) == HackleValue.string("default")
                expect(actual.remoteConfigResult.reason) == DecisionReason.IDENTIFIER_NOT_FOUND
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

                matcher.matchedRule = targetRule

                let request = remoteConfigRequest(parameter: parameter)

                // when
                let response: RemoteConfigEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())
                let actual = response.remoteConfigEvaluation

                // then
                expect(actual.remoteConfigResult.valueId) == 320
                expect(actual.remoteConfigResult.value) == HackleValue.string("targetRuleValue")
                expect(actual.remoteConfigResult.reason) == DecisionReason.TARGET_RULE_MATCH
                expect(actual.properties["requestValueType"] as? String) == "STRING"
                expect(actual.properties["requestDefaultValue"] as? String) == "default"
                expect(actual.properties["returnValue"] as? String) == "targetRuleValue"
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

                matcher.matchedRule = nil

                let request = remoteConfigRequest(parameter: parameter)

                // when
                let response: RemoteConfigEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())
                let actual = response.remoteConfigEvaluation

                // then
                expect(actual.remoteConfigResult.valueId) == 43
                expect(actual.remoteConfigResult.value) == HackleValue.string("hello value")
                expect(actual.remoteConfigResult.reason) == DecisionReason.DEFAULT_RULE
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
                matcher.matchedRule = nil

                let request = remoteConfigRequest(parameter: parameter, defaultValue: v2)

                let response: RemoteConfigEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())
                let actual = response.remoteConfigEvaluation

                if isMatch {
                    expect(actual.remoteConfigResult.valueId) == 43
                    expect(actual.remoteConfigResult.value) == v1
                    expect(actual.remoteConfigResult.reason) == DecisionReason.DEFAULT_RULE
                } else {
                    expect(actual.remoteConfigResult.valueId).to(beNil())
                    expect(actual.remoteConfigResult.value) == v2
                    expect(actual.remoteConfigResult.reason) == DecisionReason.TYPE_MISMATCH
                }
            }
        }
    }
}

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultEvaluatorSpecs: QuickSpec {
    override func spec() {

        describe("evaluateExperiment") {
            it("evaluationFlowFactory에서 ExperimentType으로 Flow를 가져와서 평가한다") {

                // given
                let evaluationFlow = MockEvaluationFlow()
                let evaluation = Evaluation(variationId: 42, variationKey: "B", reason: DecisionReason.DEFAULT_RULE, config: nil)
                every(evaluationFlow.evaluateMock).returns(evaluation)

                let factory = EvaluationFlowFactoryStub(flow: evaluationFlow)

                let sut = DefaultEvaluator(evaluationFlowFactory: factory)

                // when
                let actual = try sut.evaluateExperiment(workspace: MockWorkspace(), experiment: MockExperiment(), user: HackleUser.of(userId: "test"), defaultVariationKey: "A")

                // then
                expect(actual).to(equal(evaluation))
            }
        }

        describe("evaluateRemoteConfig") {
            var remoteConfigParameterTargetRuleDeterminer: MockRemoteConfigTargetRuleDeterminer!
            var sut: DefaultEvaluator!

            let user = HackleUser.of(userId: "test")

            beforeEach {
                remoteConfigParameterTargetRuleDeterminer = MockRemoteConfigTargetRuleDeterminer()
                every(remoteConfigParameterTargetRuleDeterminer.determineTargetRuleOrNilMock).returns(nil)
                let factory = EvaluationFlowFactoryStub(remoteConfigTargetRuleDeterminer: remoteConfigParameterTargetRuleDeterminer)
                sut = DefaultEvaluator(evaluationFlowFactory: factory)
            }

            it("식별자가 없는 경우") {
                // given
                let parameter = parameter(
                    type: .string,
                    identifierType: "customId",
                    defaultValue: RemoteConfigParameter.Value(id: 43, rawValue: HackleValue.string("hello value"))
                )

                // when
                let actual = try sut.evaluateRemoteConfig(workspace: MockWorkspace(), parameter: parameter, user: user, defaultValue: HackleValue.string("default"))

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

                every(remoteConfigParameterTargetRuleDeterminer.determineTargetRuleOrNilMock).returns(targetRule)

                // when
                let actual = try sut.evaluateRemoteConfig(workspace: MockWorkspace(), parameter: parameter, user: user, defaultValue: HackleValue.string("default"))

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

                every(remoteConfigParameterTargetRuleDeterminer.determineTargetRuleOrNilMock).returns(nil)

                // when
                let actual = try sut.evaluateRemoteConfig(workspace: MockWorkspace(), parameter: parameter, user: user, defaultValue: HackleValue.string("default"))

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
                every(remoteConfigParameterTargetRuleDeterminer.determineTargetRuleOrNilMock).returns(nil)
                let actual = try sut.evaluateRemoteConfig(workspace: MockWorkspace(), parameter: parameter, user: user, defaultValue: v2)

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
        }
    }
}

private class EvaluationFlowFactoryStub: EvaluationFlowFactory {
    private let flow: EvaluationFlow
    let remoteConfigTargetRuleDeterminer: RemoteConfigTargetRuleDeterminer

    init(flow: EvaluationFlow = MockEvaluationFlow(), remoteConfigTargetRuleDeterminer: RemoteConfigTargetRuleDeterminer = MockRemoteConfigTargetRuleDeterminer()) {
        self.flow = flow
        self.remoteConfigTargetRuleDeterminer = remoteConfigTargetRuleDeterminer
    }

    func getFlow(experimentType: ExperimentType) -> EvaluationFlow {
        flow
    }
}

import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class DefaultRemoteConfigTargetRuleDeterminerSpecs: QuickSpec {
    override func spec() {

        var matcher: RemoteConfigTargetRuleMatcherStub!
        var sut: DefaultRemoteConfigTargetRuleDeterminer!

        let user = HackleUser.of(userId: "test_id")

        beforeEach {
            matcher = RemoteConfigTargetRuleMatcherStub()
            sut = DefaultRemoteConfigTargetRuleDeterminer(matcher: matcher)
        }

        it("첫번째로 매치되는 룰을 리턴한다") {
            // given
            let matchRule = targetRule(true)
            let parameter = parameter(
                targetRule(false),
                targetRule(false),
                matchRule,
                targetRule(false)
            )

            let request = RemoteConfigRequest.of(workspace: MockWorkspace(), user: user, parameter: parameter, defaultValue: .string("go"))

            // when
            let actual = try sut.determineTargetRuleOrNil(request: request, context: Evaluators.context())

            // then
            expect(actual).to(beIdenticalTo(matchRule))
        }

        it("매치되는 룰이 없으면 nil 리턴") {
            // given
            let parameter = parameter(
                targetRule(false),
                targetRule(false),
                targetRule(false),
                targetRule(false),
                targetRule(false)
            )

            let request = RemoteConfigRequest.of(workspace: MockWorkspace(), user: user, parameter: parameter, defaultValue: .string("go"))

            // when
            let actual = try sut.determineTargetRuleOrNil(request: request, context: Evaluators.context())

            // then
            expect(actual).to(beNil())
        }

        it("TargetRule 이 없으면 nil 리턴") {
            // given
            let parameter = parameter()

            let request = RemoteConfigRequest.of(workspace: MockWorkspace(), user: user, parameter: parameter, defaultValue: .string("go"))

            // when
            let actual = try sut.determineTargetRuleOrNil(request: request, context: Evaluators.context())

            // then
            expect(actual).to(beNil())
        }

        func parameter(_ targetRules: RemoteConfigParameter.TargetRule...) -> RemoteConfigParameter {
            RemoteConfigParameter(
                id: 42,
                key: "key",
                type: HackleValueType.string,
                identifierType: "$id",
                targetRules: targetRules,
                defaultValue: RemoteConfigParameter.Value(id: 320, rawValue: HackleValue.string("default value"))
            )
        }

        func targetRule(_ isMatch: Bool) -> RemoteConfigParameter.TargetRule {
            let targetRule = RemoteConfigParameter.TargetRule(
                key: "test_rule_key",
                name: "Test Rule",
                target: Target(conditions: []),
                bucketId: 42,
                value: RemoteConfigParameter.Value(id: 320, rawValue: HackleValue.string("test_value"))
            )

            matcher.add(targetRule: targetRule, isMatch: isMatch)
            return targetRule
        }
    }


    class RemoteConfigTargetRuleMatcherStub: RemoteConfigTargetRuleMatcher {

        private var mocks: [(RemoteConfigParameter.TargetRule, Bool)] = []

        func add(targetRule: RemoteConfigParameter.TargetRule, isMatch: Bool) {
            mocks.append((targetRule, isMatch))
        }

        func matches(request: RemoteConfigRequest, context: EvaluatorContext, targetRule: RemoteConfigParameter.TargetRule) throws -> Bool {
            let mock = mocks.first { it in
                it.0 === targetRule
            }

            return mock!.1
        }
    }
}
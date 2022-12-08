import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class DefaultRemoteConfigTargetRuleMatcherSpecs: QuickSpec {
    override func spec() {

        var targetMatcher: MockTargetMatcher!
        var bucketer: MockBucketer!
        var sut: DefaultRemoteConfigTargetRuleMatcher!

        beforeEach {
            targetMatcher = MockTargetMatcher()
            bucketer = MockBucketer()
            sut = DefaultRemoteConfigTargetRuleMatcher(targetMatcher: targetMatcher, buckter: bucketer)
        }

        it("Target 에 매치되지 않으면 false") {
            // given
            let targetRule = targetRule(isTargetMatch: false)
            let parameter = parameter()
            let user = HackleUser.of(userId: "test")

            // when
            let actual = try sut.matches(targetRule: targetRule, workspace: MockWorkspace(), parameter: parameter, user: user)

            // then
            expect(actual) == false
        }

        it("식별자가 없으면 false") {
            // given
            let targetRule = targetRule(isTargetMatch: true)
            let parameter = parameter(identifierType: "customId")
            let user = HackleUser.of(userId: "test")

            // when
            let actual = try sut.matches(targetRule: targetRule, workspace: MockWorkspace(), parameter: parameter, user: user)

            // then
            expect(actual) == false
        }

        it("Bucket 을 찾을 수 없으면 에러") {
            // given
            let targetRule = targetRule(isTargetMatch: true)
            let parameter = parameter()
            let user = HackleUser.of(userId: "test")

            let workspace = MockWorkspace()
            every(workspace.getBucketOrNilMock).returns(nil)

            // when
            expect(try sut.matches(targetRule: targetRule, workspace: workspace, parameter: parameter, user: user))
                .to(throwError(HackleError.error("Bucket[420]")))
        }

        it("Slot 에 할당 되어 있지 않으면 false") {
            // given
            let targetRule = targetRule(isTargetMatch: true)
            let parameter = parameter()
            let user = HackleUser.of(userId: "test")

            let bucket = MockBucket()
            every(bucketer.bucketingMock).returns(nil)

            let workspace = MockWorkspace()
            every(workspace.getBucketOrNilMock).returns(bucket)

            // when
            let actual = try sut.matches(targetRule: targetRule, workspace: workspace, parameter: parameter, user: user)

            // then
            expect(actual) == false
        }

        it("Slot 에 할당 되어 있으면 true") {
            // given
            let targetRule = targetRule(isTargetMatch: true)
            let parameter = parameter()
            let user = HackleUser.of(userId: "test")

            let bucket = MockBucket()
            every(bucketer.bucketingMock).returns(MockSlot())

            let workspace = MockWorkspace()
            every(workspace.getBucketOrNilMock).returns(bucket)

            // when
            let actual = try sut.matches(targetRule: targetRule, workspace: workspace, parameter: parameter, user: user)

            // then
            expect(actual) == true
        }

        func targetRule(isTargetMatch: Bool) -> RemoteConfigParameter.TargetRule {
            every(targetMatcher.matchesMock).returns(isTargetMatch)
            return RemoteConfigParameter.TargetRule(
                key: "rule_key",
                name: "Rule Name",
                target: Target(conditions: []),
                bucketId: 420,
                value: RemoteConfigParameter.Value(id: 320, rawValue: HackleValue.string("str"))
            )
        }

        func parameter(identifierType: String = "$id") -> RemoteConfigParameter {
            RemoteConfigParameter(id: 42, key: "key", type: .string, identifierType: identifierType, targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 320, rawValue: HackleValue.string("str")))
        }
    }
}

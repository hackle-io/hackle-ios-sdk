import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultOverrideResolverSpecs: QuickSpec {
    override func spec() {

        var targetMatcher: TargetMatcherStub!
        var actionResolver: MockActionResolver!
        var sut: DefaultOverrideResolver!

        beforeEach {
            targetMatcher = TargetMatcherStub()
            actionResolver = MockActionResolver()
            sut = DefaultOverrideResolver(targetMatcher: targetMatcher, actionResolver: actionResolver)
        }

        it("userOverride 를 먼저 평가한다") {
            // given
            let experiment = MockExperiment(
                userOverrides: ["user_01": 42]
            )
            let variation = MockVariation()
            every(experiment.getVariationByIdOrNilMock).returns(variation)

            // when
            let actual = try sut.resolveOrNil(workspace: MockWorkspace(), experiment: experiment, user: HackleUser.of(userId: "user_01"))

            // then
            expect(actual).to(beIdenticalTo(variation))
        }

        it("userOverride 가 없으면 segmentOverride 를 확인한다") {
            // given
            let experiment = MockExperiment(
                segmentOverrides: [userSegment(isMatch: true)]
            )
            let variation = MockVariation()
            every(actionResolver.resolveOrNilMock).returns(variation)

            // when
            let actual = try sut.resolveOrNil(workspace: MockWorkspace(), experiment: experiment, user: HackleUser.of(userId: "user_01"))

            // then
            expect(actual).to(beIdenticalTo(variation))
        }

        it("userOverride 는 첫번째로 매칭된 rule 로 평가한다") {
            // given
            let experiment = MockExperiment(
                segmentOverrides: [
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: true),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                ]
            )
            let variation = MockVariation()
            every(actionResolver.resolveOrNilMock).returns(variation)

            // when
            let actual = try sut.resolveOrNil(workspace: MockWorkspace(), experiment: experiment, user: HackleUser.of(userId: "user_01"))

            // then
            expect(actual).to(beIdenticalTo(variation))
            expect(targetMatcher.callCount) == 4
        }

        it("override 되어 있지 않으면 nil 을 리턴한다") {
            // given
            let experiment = MockExperiment(
                userOverrides: [
                    "user_01": 42
                ],
                segmentOverrides: [
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                    userSegment(isMatch: false),
                ]
            )

            // when
            let actual = try sut.resolveOrNil(workspace: MockWorkspace(), experiment: experiment, user: HackleUser.of(userId: "user_02"))

            // then
            expect(actual).to(beNil())
        }

        func userSegment(isMatch: Bool) -> TargetRule {
            let targetRule = MockTargetRule()
            targetMatcher.addResult(target: targetRule.target, isMatch: isMatch)
            return targetRule
        }
    }

    private class TargetMatcherStub: TargetMatcher {

        private var matches = [(Target, Bool)]()
        var callCount = 0

        func matches(target: Target, workspace: Workspace, user: HackleUser) throws -> Bool {
            callCount = callCount + 1
            guard let match = matches.first(where: { $0.0 === target }) else {
                throw HackleError.error("error")
            }
            return match.1
        }

        func addResult(target: Target, isMatch: Bool) {
            matches.append((target, isMatch))
        }
    }
}

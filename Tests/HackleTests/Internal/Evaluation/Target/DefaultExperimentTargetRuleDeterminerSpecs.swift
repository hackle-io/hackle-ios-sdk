import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultTargetRuleDeterminerSpecs: QuickSpec {
    override func spec() {

        it("첫 번째로 일치하는 타겟룰을 리턴한다") {
            // given
            let matchedTargetRule = MockTargetRule()
            let experiment = MockExperiment(targetRules: [
                MockTargetRule(),
                MockTargetRule(),
                MockTargetRule(),
                matchedTargetRule,
                MockTargetRule()
            ])

            let matcher = TargetMatcherStub.of(false, false, false, true, false)
            let sut = DefaultExperimentTargetRuleDeterminer(targetMatcher: matcher)

            // when
            let actual = try sut.determineTargetRuleOrNil(workspace: MockWorkspace(), experiment: experiment, user: HackleUser.of(userId: "test"))

            // then
            expect(actual).to(beIdenticalTo(matchedTargetRule))
            expect(matcher.callCount).to(equal(4))
        }

        it("실험의 타겟룰중 일치하는 타겟이 하나도 없으면 nil을 리턴한다") {
            // given
            let experiment = MockExperiment(targetRules: [
                MockTargetRule(),
                MockTargetRule(),
                MockTargetRule(),
                MockTargetRule(),
                MockTargetRule()
            ])

            let matcher = TargetMatcherStub.of(false, false, false, false, false)
            let sut = DefaultExperimentTargetRuleDeterminer(targetMatcher: matcher)

            // when
            let actual = try sut.determineTargetRuleOrNil(workspace: MockWorkspace(), experiment: experiment, user: HackleUser.of(userId: "test"))

            // then
            expect(actual).to(beNil())
            expect(matcher.callCount).to(equal(5))
        }
    }
}

private class TargetMatcherStub: TargetMatcher {

    private let isMatches: [Bool]
    private var index = 0
    var callCount = 0

    init(isMatches: [Bool]) {
        self.isMatches = isMatches
    }

    static func of(_ isMatches: Bool...) -> TargetMatcherStub {
        TargetMatcherStub(isMatches: isMatches)
    }

    func matches(target: Target, workspace: Workspace, user: HackleUser) -> Bool {
        let isMatch = isMatches[index]
        index = index + 1
        callCount = callCount + 1
        return isMatch
    }
}
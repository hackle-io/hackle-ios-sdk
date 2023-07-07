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

            let request = experimentRequest(experiment: experiment)

            // when
            let actual = try sut.determineTargetRuleOrNil(request: request, context: Evaluators.context())

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

            let request = experimentRequest(experiment: experiment)

            // when
            let actual = try sut.determineTargetRuleOrNil(request: request, context: Evaluators.context())

            // then
            expect(actual).to(beNil())
            expect(matcher.callCount).to(equal(5))
        }
    }
}

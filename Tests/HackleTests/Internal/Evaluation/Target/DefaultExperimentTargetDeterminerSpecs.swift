import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultExperimentTargetDeterminerSpecs: QuickSpec {
    override func spec() {


        it("Audience가 비어 있으면 true") {
            // given
            let sut = DefaultExperimentTargetDeterminer(targetMatcher: TargetMatcherStub.of(false, false))
            let experiment = experiment(targetAudiences: [])
            let request = experimentRequest(experiment: experiment)

            // when
            let actual = try sut.isUserInExperimentTarget(request: request, context: Evaluators.context())

            // then
            expect(actual).to(beTrue())
        }

        it("하나라도 일치하면 true") {
            // given
            let matcher = TargetMatcherStub.of(false, false, false, true, false)
            let sut = DefaultExperimentTargetDeterminer(targetMatcher: matcher)

            let experiment = experiment(targetAudiences: self.audiences())
            let request = experimentRequest(experiment: experiment)

            // when
            let actual = try sut.isUserInExperimentTarget(request: request, context: Evaluators.context())

            // then
            expect(actual).to(beTrue())
            expect(matcher.callCount).to(equal(4))
        }

        it("하나라도 일치하는게 없으면 false") {
            // given
            let matcher = TargetMatcherStub.of(false, false, false, false, false)
            let sut = DefaultExperimentTargetDeterminer(targetMatcher: matcher)

            let experiment = experiment(targetAudiences: self.audiences())
            let request = experimentRequest(experiment: experiment)

            // when
            let actual = try sut.isUserInExperimentTarget(request: request, context: Evaluators.context())

            // then
            expect(actual).to(beFalse())
            expect(matcher.callCount).to(equal(5))
        }
    }

    private func audiences() -> [Target] {
        [
            Target(conditions: [condition()]),
            Target(conditions: [condition()]),
            Target(conditions: [condition()]),
            Target(conditions: [condition()]),
            Target(conditions: [condition()])
        ]
    }

    private func condition() -> Target.Condition {
        Target.Condition(key: Target.Key(type: .userProperty, name: "age"), match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [HackleValue(value: 1)]))
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

    func matches(request: EvaluatorRequest, context: EvaluatorContext, target: Target) throws -> Bool {
        let isMatch = isMatches[index]
        index = index + 1
        callCount = callCount + 1
        return isMatch
    }
}
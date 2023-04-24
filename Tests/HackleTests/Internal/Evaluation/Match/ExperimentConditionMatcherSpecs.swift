//
//  ExperimentConditionMatcherSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class ExperimentConditionMatcherSpecs: QuickSpec {
    override func spec() {

        var abTestMatcher: MockExperimentMatcher!
        var featureFlagMatcher: MockExperimentMatcher!
        var sut: ExperimentConditionMatcher!

        beforeEach {
            abTestMatcher = MockExperimentMatcher()
            featureFlagMatcher = MockExperimentMatcher()
            sut = ExperimentConditionMatcher(abTestMatcher: abTestMatcher, featureFlagMatcher: featureFlagMatcher)
        }

        it("AB_TEST") {
            let request = experimentRequest(experiment: experiment(type: .abTest))
            let condition = Target.Condition(
                key: Target.Key(type: .abTest, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [.string("A")])
            )
            every(abTestMatcher.matchesMock).returns(true)

            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            expect(actual) == true
            verify {
                abTestMatcher.matchesMock
            }
        }

        it("FEATURE_FLAG") {
            let request = experimentRequest(experiment: experiment(type: .featureFlag))
            let condition = Target.Condition(
                key: Target.Key(type: .featureFlag, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .bool, values: [.bool(true)])
            )
            every(featureFlagMatcher.matchesMock).returns(true)

            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            expect(actual) == true
            verify {
                featureFlagMatcher.matchesMock
            }
        }

        it("Unsupport") {
            let request = experimentRequest()

            func check(type: Target.KeyType) {
                let condition = Target.Condition(
                    key: Target.Key(type: type, name: "42"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .bool, values: [.bool(true)])
                )

                expect(try sut.matches(request: request, context: Evaluators.context(), condition: condition))
                    .to(throwError())
            }

            check(type: .userId)
            check(type: .userProperty)
            check(type: .hackleProperty)
            check(type: .segment)
        }
    }
}
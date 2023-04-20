//
//  FeatureFlagConditionMatcherSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class FeatureFlagConditionMatcherSpecs: QuickSpec {
    override func spec() {
        var evaluator: MockEvaluator!
        var valueOperatorMatcher: MockValueOperatorMatcher!
        var sut: FeatureFlagConditionMatcher!

        var context: EvaluatorContext!

        beforeEach {
            evaluator = MockEvaluator()
            valueOperatorMatcher = MockValueOperatorMatcher()
            sut = FeatureFlagConditionMatcher(evaluator: evaluator, valueOperatorMatcher: valueOperatorMatcher)
            context = Evaluators.context()
        }

        it("key 가 number 가 아닌경우") {
            let request = experimentRequest(experiment: experiment(type: .featureFlag))
            let condition = Target.Condition(
                key: Target.Key(type: .featureFlag, name: "string"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .bool, values: [.bool(true)])
            )

            expect(try sut.matches(request: request, context: context, condition: condition))
                .to(throwError(HackleError.error("Invalid key [FEATURE_FLAG, string]")))
        }

        it("experiment 가 없는 경우 false") {
            let workspace = MockWorkspace()
            every(workspace.getFeatureFlagOrNilMock).returns(nil)
            let request = experimentRequest(experiment: experiment(type: .featureFlag))
            let condition = Target.Condition(
                key: Target.Key(type: .featureFlag, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .bool, values: [.bool(true)])
            )
            let actual = try sut.matches(request: request, context: context, condition: condition)
            expect(actual) == false
        }

        func request(experiment: Experiment) -> ExperimentRequest {
            let workspace = MockWorkspace()
            every(workspace.getFeatureFlagOrNilMock).returns(experiment)
            return experimentRequest(workspace: workspace, experiment: experiment)
        }

        func evaluation(request: ExperimentRequest, reason: String) throws -> ExperimentEvaluation {
            try ExperimentEvaluation.of(request: request, context: context, variation: request.experiment.variations.first!, reason: reason)
        }

        it("신규 평가") {
            let request = request(experiment: experiment(type: .featureFlag))
            let condition = Target.Condition(
                key: Target.Key(type: .featureFlag, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .bool, values: [.bool(true)])
            )

            let evaluation = try evaluation(request: request, reason: DecisionReason.DEFAULT_RULE)
            evaluator.returns = evaluation
            every(valueOperatorMatcher.matchesMock).returns(true)

            let actual = try sut.matches(request: request, context: context, condition: condition)

            expect(actual) == true
            expect(evaluator.call) == 1
        }

        it("이미 평가된 경우") {
            let request = request(experiment: experiment(type: .featureFlag))
            let condition = Target.Condition(
                key: Target.Key(type: .featureFlag, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .bool, values: [.bool(true)])
            )

            let evaluation = try evaluation(request: request, reason: DecisionReason.DEFAULT_RULE)
            context.add(evaluation)
            evaluator.returns = evaluation
            every(valueOperatorMatcher.matchesMock).returns(true)

            let actual = try sut.matches(request: request, context: context, condition: condition)

            expect(actual) == true
            expect(evaluator.call) == 0
        }

    }
}
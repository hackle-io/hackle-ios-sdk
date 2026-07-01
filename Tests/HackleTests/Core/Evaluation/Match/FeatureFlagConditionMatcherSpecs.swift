//
//  FeatureFlagConditionMatcherSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class FeatureFlagConditionMatcherSpecs: QuickSpec {
    override class func spec() {
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

        func evaluation(request: ExperimentLocalEvaluateRequest, reason: String) -> ExperimentEvaluation {
            ExperimentEvaluation(
                entity: request.experiment,
                result: ExperimentEvaluateResult.of(reason: reason, variation: request.experiment.variations.first!, config: nil)
            )
        }

        func response(request: ExperimentLocalEvaluateRequest, evaluation: ExperimentEvaluation) -> ExperimentEvaluateResponse {
            ExperimentEvaluateResponse(user: request.user, workspace: request.workspace, evaluation: evaluation, references: [])
        }

        func request(experiment: ExperimentConfig) -> ExperimentLocalEvaluateRequest {
            let workspace = MockWorkspace()
            every(workspace.getFeatureFlagOrNilMock).returns(experiment)
            return experimentRequest(workspace: workspace, experiment: experiment)
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
            let request = experimentRequest(workspace: workspace, experiment: experiment(type: .featureFlag))
            let condition = Target.Condition(
                key: Target.Key(type: .featureFlag, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .bool, values: [.bool(true)])
            )
            let actual = try sut.matches(request: request, context: context, condition: condition)
            expect(actual) == false
        }

        it("신규 평가") {
            let request = request(experiment: experiment(type: .featureFlag))
            let condition = Target.Condition(
                key: Target.Key(type: .featureFlag, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .bool, values: [.bool(true)])
            )

            let evaluation = evaluation(request: request, reason: DecisionReason.DEFAULT_RULE)
            evaluator.returns = response(request: request, evaluation: evaluation)
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

            let evaluation = evaluation(request: request, reason: DecisionReason.DEFAULT_RULE)
            context.add(evaluation)
            evaluator.returns = response(request: request, evaluation: evaluation)
            every(valueOperatorMatcher.matchesMock).returns(true)

            let actual = try sut.matches(request: request, context: context, condition: condition)

            expect(actual) == true
            expect(evaluator.call) == 0
        }
    }
}

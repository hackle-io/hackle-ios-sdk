//
//  AbTestConditionMatcherSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class AbTestConditionMatcherSpecs: QuickSpec {
    override func spec() {
        var evaluator: MockEvaluator!
        var valueOperatorMatcher: MockValueOperatorMatcher!
        var sut: AbTestConditionMatcher!

        var context: EvaluatorContext!

        beforeEach {
            evaluator = MockEvaluator()
            valueOperatorMatcher = MockValueOperatorMatcher()
            sut = AbTestConditionMatcher(evaluator: evaluator, valueOperatorMatcher: valueOperatorMatcher)
            context = Evaluators.context()
        }

        it("key 가 number 가 아닌경우") {
            let request = experimentRequest(experiment: experiment(type: .abTest))
            let condition = Target.Condition(
                key: Target.Key(type: .abTest, name: "string"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [.string("A")])
            )

            expect(try sut.matches(request: request, context: context, condition: condition))
                .to(throwError(HackleError.error("Invalid key [AB_TEST, string]")))
        }

        it("experiment 가 없는 경우 false") {
            let workspace = MockWorkspace()
            every(workspace.getExperimentOrNilMock).returns(nil)
            let request = experimentRequest(workspace: workspace, experiment: experiment(type: .abTest))
            let condition = Target.Condition(
                key: Target.Key(type: .abTest, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [.string("A")])
            )

            let actual = try sut.matches(request: request, context: context, condition: condition)
            expect(actual) == false
        }

        func request(experiment: Experiment) -> ExperimentRequest {
            let workspace = MockWorkspace()
            every(workspace.getExperimentOrNilMock).returns(experiment)
            return experimentRequest(workspace: workspace, experiment: experiment)
        }

        func evaluation(request: ExperimentRequest, reason: String) throws -> ExperimentEvaluation {
            try ExperimentEvaluation.of(request: request, context: context, variation: request.experiment.variations.first!, reason: reason)
        }

        it("매칭 대상 분배사유가 아니면 false") {

            func check(reason: String) throws {
                let request = request(experiment: experiment(type: .abTest))
                let condition = Target.Condition(
                    key: Target.Key(type: .abTest, name: "42"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [.string("A")])
                )

                let evaluation = try evaluation(request: request, reason: reason)
                evaluator.returns = evaluation

                let actual = try sut.matches(request: request, context: context, condition: condition)
                expect(actual) == false
            }

            try check(reason: DecisionReason.EXPERIMENT_DRAFT)
            try check(reason: DecisionReason.EXPERIMENT_PAUSED)
            try check(reason: DecisionReason.NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT)
            try check(reason: DecisionReason.VARIATION_DROPPED)
            try check(reason: DecisionReason.NOT_IN_EXPERIMENT_TARGET)
        }

        it("매칭 대상 분배사유면 Variation 확인") {

            func check(reason: String) throws {
                let request = request(experiment: experiment(type: .abTest))
                let condition = Target.Condition(
                    key: Target.Key(type: .abTest, name: "42"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [.string("A")])
                )

                let evaluation = try evaluation(request: request, reason: reason)
                evaluator.returns = evaluation
                every(valueOperatorMatcher.matchesMock).returns(true)

                let actual = try sut.matches(request: request, context: context, condition: condition)
                expect(actual) == true
            }

            try check(reason: DecisionReason.OVERRIDDEN)
            try check(reason: DecisionReason.TRAFFIC_ALLOCATED)
            try check(reason: DecisionReason.TRAFFIC_ALLOCATED_BY_TARGETING)
            try check(reason: DecisionReason.EXPERIMENT_COMPLETED)
        }

        it("이미 평가된 Experiment 는 다시 평가하지 않는다") {
            let request = request(experiment: experiment(type: .abTest))
            let condition = Target.Condition(
                key: Target.Key(type: .abTest, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [.string("A")])
            )

            let evaluation = try evaluation(request: request, reason: DecisionReason.TRAFFIC_ALLOCATED)
            evaluator.returns = evaluation
            every(valueOperatorMatcher.matchesMock).returns(true)

            context.add(evaluation)

            let actual = try sut.matches(request: request, context: context, condition: condition)

            expect(actual) == true
            expect(context.targetEvaluations.count) == 1
        }

        it("ExperimentRequest + TRAFFIC_ALLOCATED 인경우 분배 사유를 변경한다") {
            let request = request(experiment: experiment(type: .abTest))
            let condition = Target.Condition(
                key: Target.Key(type: .abTest, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [.string("A")])
            )

            let evaluation = try evaluation(request: request, reason: DecisionReason.TRAFFIC_ALLOCATED)
            evaluator.returns = evaluation
            every(valueOperatorMatcher.matchesMock).returns(true)

            let actual = try sut.matches(request: request, context: context, condition: condition)

            expect(actual) == true
            expect(context.get(request.experiment)).toNot(beNil())
            expect(context.get(request.experiment)?.reason) == DecisionReason.TRAFFIC_ALLOCATED_BY_TARGETING
        }

        it("ExperimentRequest + TRAFFIC_ALLOCATED 분배 사유가 아니면 evaluation 그대로 사용") {
            let request = request(experiment: experiment(type: .abTest))
            let condition = Target.Condition(
                key: Target.Key(type: .abTest, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [.string("A")])
            )

            let evaluation = try evaluation(request: request, reason: DecisionReason.OVERRIDDEN)
            evaluator.returns = evaluation
            every(valueOperatorMatcher.matchesMock).returns(true)

            let actual = try sut.matches(request: request, context: context, condition: condition)

            expect(actual) == true
            expect(context.get(request.experiment)).to(beIdenticalTo(evaluation))
        }

        it("ExperimentRequest 가 아니면 evaluation 그대로 사용") {
            let experimentRequest = request(experiment: experiment(type: .abTest))
            let request = remoteConfigRequest(workspace: experimentRequest.workspace)
            let condition = Target.Condition(
                key: Target.Key(type: .abTest, name: "42"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [.string("A")])
            )

            let evaluation = try evaluation(request: experimentRequest, reason: DecisionReason.OVERRIDDEN)
            evaluator.returns = evaluation
            every(valueOperatorMatcher.matchesMock).returns(true)

            let actual = try sut.matches(request: request, context: context, condition: condition)

            expect(actual) == true
            expect(context.get(experimentRequest.experiment)).to(beIdenticalTo(evaluation))
        }
    }
}
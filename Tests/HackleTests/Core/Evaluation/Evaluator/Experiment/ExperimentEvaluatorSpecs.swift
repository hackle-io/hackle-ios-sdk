//
//  ExperimentEvaluatorSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class ExperimentEvaluatorSpecs: QuickSpec {

    override func spec() {

        var evaluationFlowFactory: MockEvaluationFlowFactory!
        var sut: ExperimentEvaluator!

        beforeEach {
            evaluationFlowFactory = MockEvaluationFlowFactory()
            sut = ExperimentEvaluator(evaluationFlowFactory: evaluationFlowFactory)
        }

        it("supports") {
            expect(sut.support(request: experimentRequest())) == true
            expect(sut.support(request: remoteConfigRequest())) == false
        }

        describe("evaluate") {
            it("circular") {
                let request = experimentRequest()
                let context = Evaluators.context()
                context.add(request)

                expect {
                    let _: ExperimentEvaluation = try sut.evaluate(request: request, context: context)
                }
                    .to(throwError())
            }

            context("flow") {
                it("evaluation") {
                    let evaluation = experimentEvaluation()
                    let flow: EvaluationFlow<ExperimentRequest, ExperimentEvaluation> = EvaluationFlow<ExperimentRequest, ExperimentEvaluation>.create(evaluation)
                    evaluationFlowFactory.experimentFlow = flow

                    let request = experimentRequest()
                    let context = Evaluators.context()

                    let actual: ExperimentEvaluation = try sut.evaluate(request: request, context: context)

                    expect(actual).to(beIdenticalTo(evaluation))
                }

                it("default") {
                    let request = experimentRequest()
                    let context = Evaluators.context()

                    let actual: ExperimentEvaluation = try sut.evaluate(request: request, context: context)

                    expect(actual.reason) == DecisionReason.TRAFFIC_NOT_ALLOCATED
                }
            }
        }
    }
}

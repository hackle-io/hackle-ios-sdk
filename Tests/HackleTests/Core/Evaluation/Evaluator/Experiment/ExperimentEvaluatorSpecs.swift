//
//  ExperimentEvaluatorSpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class ExperimentEvaluatorSpecs: QuickSpec {

    override class func spec() {

        var flowFactory: MockExperimentFlowFactory!
        var eventRecorder: MockEvaluationEventRecorder!
        var sut: ExperimentLocalEvaluator!

        beforeEach {
            flowFactory = MockExperimentFlowFactory()
            eventRecorder = MockEvaluationEventRecorder()
            sut = ExperimentLocalEvaluator(evaluationFlowFactory: flowFactory, eventRecorder: eventRecorder)
        }

        it("supports") {
            expect(sut.supports(request: experimentRequest())) == true
            expect(sut.supports(request: remoteConfigRequest())) == false
        }

        describe("evaluate") {
            it("circular") {
                let request = experimentRequest()
                let context = Evaluators.context()
                context.add(request)

                expect {
                    let _: ExperimentEvaluateResponse = try sut.evaluate(request: request, context: context)
                }
                    .to(throwError())
            }

            context("flow") {
                it("evaluation") {
                    let evaluation = experimentEvaluation()
                    let flow: ExperimentLocalEvaluationFlow = ExperimentLocalEvaluationFlow.create(evaluation)
                    every(flowFactory.getMock).returns(flow)

                    let request = experimentRequest()
                    let context = Evaluators.context()

                    let actual: ExperimentEvaluateResponse = try sut.evaluate(request: request, context: context)

                    expect(actual.experimentEvaluation).to(beIdenticalTo(evaluation))
                }

                it("default") {
                    let flow: ExperimentLocalEvaluationFlow = ExperimentLocalEvaluationFlow.end()
                    every(flowFactory.getMock).returns(flow)

                    let request = experimentRequest()
                    let context = Evaluators.context()

                    let actual: ExperimentEvaluateResponse = try sut.evaluate(request: request, context: context)

                    expect(actual.experimentEvaluation.experimentResult.reason) == DecisionReason.TRAFFIC_NOT_ALLOCATED
                }
            }
        }
    }
}

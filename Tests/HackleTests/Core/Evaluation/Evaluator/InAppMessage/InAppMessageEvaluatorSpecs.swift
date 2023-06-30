//
//  InAppMessageEvaluatorSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEvaluatorSpecs: QuickSpec {
    override func spec() {

        var evaluationFlowFactory: MockEvaluationFlowFactory!
        var sut: InAppMessageEvaluator!

        beforeEach {
            evaluationFlowFactory = MockEvaluationFlowFactory()
            sut = InAppMessageEvaluator(evaluationFlowFactory: evaluationFlowFactory)
        }

        it("supports") {
            expect(sut.support(request: experimentRequest())) == false
            expect(sut.support(request: remoteConfigRequest())) == false
            expect(sut.support(request: InAppMessage.request())) == true
        }

        describe("evaluate") {
            it("circular") {
                let request = InAppMessage.request()
                let context = Evaluators.context()
                context.add(request)

                expect {
                    let _: InAppMessageEvaluation = try sut.evaluate(request: request, context: context)
                }
                    .to(throwError())
            }

            context("flow") {
                it("evaluation") {
                    let evaluation = InAppMessage.evaluation()

                    let flow: InAppMessageFlow = InAppMessageFlow.create(evaluation)
                    evaluationFlowFactory.inAppMessageFlow = flow

                    let request = InAppMessage.request()
                    let context = Evaluators.context()

                    let actual: InAppMessageEvaluation = try sut.evaluate(request: request, context: context)

                    expect(actual).to(beIdenticalTo(evaluation))
                }

                it("default") {
                    let request = InAppMessage.request()
                    let context = Evaluators.context()

                    let actual: InAppMessageEvaluation = try sut.evaluate(request: request, context: context)

                    expect(actual.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET
                }
            }
        }
    }
}
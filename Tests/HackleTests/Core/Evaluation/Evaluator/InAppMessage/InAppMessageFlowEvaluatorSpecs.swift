//
//  InAppMessageFlowEvaluatorSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageFlowEvaluatorSpecs: QuickSpec {
    override func spec() {

        var nextFlow: InAppMessageFlow!
        var evaluation: InAppMessageEvaluation!
        var context: EvaluatorContext!

        beforeEach {
            evaluation = InAppMessage.evaluation()
            nextFlow = InAppMessageFlow.create(evaluation)
            context = Evaluators.context()
        }

        describe("InAppMessageFlowEvaluator") {

            let evaluation = InAppMessage.evaluation()

            class Sut: InAppMessageFlowEvaluator {
                private let evaluation: InAppMessageEvaluation?

                init(evaluation: InAppMessageEvaluation?) {
                    self.evaluation = evaluation
                }

                func evaluateInAppMessage(request: InAppMessageRequest, context: EvaluatorContext, nextFlow: InAppMessageFlow) throws -> InAppMessageEvaluation? {
                    evaluation
                }
            }

            let sut = Sut(evaluation: evaluation)

            it("must be InAppMessageRequest") {
                expect {
                    let _: ExperimentEvaluation? = try sut.evaluate(request: experimentRequest(), context: Evaluators.context(), nextFlow: ExperimentFlow.end())
                }
                    .to(throwError())
            }

            it("must be InAppMessageFlow") {
                expect {
                    let _: ExperimentEvaluation? = try sut.evaluate(request: InAppMessage.request(), context: Evaluators.context(), nextFlow: EvaluationFlow<InAppMessageRequest, ExperimentEvaluation>.end())
                }
                    .to(throwError())
            }

            it("evaluate") {
                expect(try sut.evaluate(request: InAppMessage.request(), context: Evaluators.context(), nextFlow: nextFlow)).to(beIdenticalTo(evaluation))
            }

            it("evaluate nil") {
                expect(try Sut(evaluation: nil).evaluate(request: InAppMessage.request(), context: Evaluators.context(), nextFlow: nextFlow)).to(beNil())
            }
        }

        describe("PlatformInAppMessageFlowEvaluator") {

            let sut: PlatformInAppMessageFlowEvaluator = PlatformInAppMessageFlowEvaluator()

            it("when inAppMessage does not support ios then evaluated as nil") {
                let inAppMessage = InAppMessage.create(messageContext: InAppMessage.context(platformTypes: []))
                let request = InAppMessage.request(inAppMessage: inAppMessage)

                let evaluation = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                expect(evaluation.reason) == DecisionReason.UNSUPPORTED_PLATFORM
            }

            it("when iam supports ios then evaluate next flow") {

                let request = InAppMessage.request()
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("OverrideInAppMessageFlowEvaluator") {

            var userOverrideMatcher: InAppMessageMatcherStub!
            var inAppMessageResolver: InAppMessageResolverStub!
            var sut: OverrideInAppMessageFlowEvaluator!

            beforeEach {
                userOverrideMatcher = InAppMessageMatcherStub()
                inAppMessageResolver = InAppMessageResolverStub()
                sut = OverrideInAppMessageFlowEvaluator(userOverrideMatcher: userOverrideMatcher, inAppMessageResolver: inAppMessageResolver)
            }

            it("when user is overridden then evaluated as OVERRIDDEN") {
                // given
                userOverrideMatcher.isMatched = true

                let request = InAppMessage.request()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.reason) == DecisionReason.OVERRIDDEN
            }

            it("when user is not overridden then evaluate next flow") {
                // given
                let request = InAppMessage.request()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("DraftInAppMessageFlowEvaluator") {

            let sut = DraftInAppMessageFlowEvaluator()

            it("when inAppMessage is draft then evaluated as nil") {
                // given
                let inAppMessage = InAppMessage.create(status: .draft)
                let request = InAppMessage.request(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.message).to(beNil())
                expect(actual.reason) == DecisionReason.IN_APP_MESSAGE_DRAFT
            }

            it("when inAppMessage is not draft then evaluate next flow") {
                // given
                let inAppMessage = InAppMessage.create(status: .active)
                let request = InAppMessage.request(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("pause") {

            let sut = PausedInAppMessageFlowEvaluator()

            it("when inAppMessage is pause then evaluated as nil") {
                // given
                let inAppMessage = InAppMessage.create(status: .pause)
                let request = InAppMessage.request(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.message).to(beNil())
                expect(actual.reason) == DecisionReason.IN_APP_MESSAGE_PAUSED
            }

            it("when inAppMessage is not pause then evaluate next flow") {
                // given
                let inAppMessage = InAppMessage.create(status: .active)
                let request = InAppMessage.request(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("PeriodInAppMessageFlowEvaluator") {

            let sut = PeriodInAppMessageFlowEvaluator()

            it("when timestamp is not in inAppMessage period then evaluated as nil") {
                // given
                let inAppMessage = InAppMessage.create(
                    period: .range(
                        startInclusive: Date(timeIntervalSince1970: 42),
                        endExclusive: Date(timeIntervalSince1970: 100)
                    )
                )
                let request = InAppMessage.request(inAppMessage: inAppMessage, timestamp: Date(timeIntervalSince1970: 100))

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.message).to(beNil())
                expect(actual.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_PERIOD
            }

            it("when timestamp is in inAppMeesage period then evaluate next flow") {
                // given
                let inAppMessage = InAppMessage.create(
                    period: .range(
                        startInclusive: Date(timeIntervalSince1970: 42),
                        endExclusive: Date(timeIntervalSince1970: 100)
                    )
                )
                let request = InAppMessage.request(inAppMessage: inAppMessage, timestamp: Date(timeIntervalSince1970: 99))

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("HiddenInAppMessageFlowEvaluator") {
            var hiddenMatcher: InAppMessageMatcherStub!
            var sut: HiddenInAppMessageFlowEvaluator!

            beforeEach {
                hiddenMatcher = InAppMessageMatcherStub()
                sut = HiddenInAppMessageFlowEvaluator(hiddenMatcher: hiddenMatcher)
            }

            it("when user is hidden then evaluated as nil") {
                // given
                hiddenMatcher.isMatched = true
                let request = InAppMessage.request()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.message).to(beNil())
                expect(actual.reason) == DecisionReason.IN_APP_MESSAGE_HIDDEN
            }

            it("when user is not hidden then evaluate next flow") {
                // given
                hiddenMatcher.isMatched = false
                let request = InAppMessage.request()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("TargetInAppMessageFlowEvaluator") {
            var targetMatcher: InAppMessageMatcherStub!
            var inAppMessageResolver: InAppMessageResolverStub!
            var sut: TargetInAppMessageFlowEvaluator!

            beforeEach {
                targetMatcher = InAppMessageMatcherStub()
                inAppMessageResolver = InAppMessageResolverStub()
                sut = TargetInAppMessageFlowEvaluator(targetMatcher: targetMatcher, inAppMessageResolver: inAppMessageResolver)
            }

            it("when user in inAppMessage target then evaluated to target message") {
                // given
                targetMatcher.isMatched = true
                let request = InAppMessage.request()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.message).toNot(beNil())
                expect(actual.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
            }

            it("when user not in inAppMessage target then evaluated as nil") {
                // given
                targetMatcher.isMatched = false
                let request = InAppMessage.request()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.message).to(beNil())
                expect(actual.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET
            }
        }
    }
}
import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEligibilityFlowEvaluatorSpecs: QuickSpec {
    override func spec() {

        var nextFlow: InAppMessageEligibilityFlow!
        var evaluation: InAppMessageEligibilityEvaluation!
        var context: EvaluatorContext!

        beforeEach {
            evaluation = InAppMessage.eligibilityEvaluation()
            nextFlow = InAppMessageEligibilityFlow.create(evaluation)
            context = Evaluators.context()
        }

        describe("InAppMessageEligibilityFlowEvaluator") {

            let evaluation = InAppMessage.eligibilityEvaluation()

            class Sut: InAppMessageEligibilityFlowEvaluator {
                private let evaluation: InAppMessageEligibilityEvaluation?

                init(evaluation: InAppMessageEligibilityEvaluation?) {
                    self.evaluation = evaluation
                }

                func evaluateInAppMessage(request: InAppMessageEligibilityRequest, context: EvaluatorContext, nextFlow: InAppMessageEligibilityFlow) throws -> InAppMessageEligibilityEvaluation? {
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
                    let _: ExperimentEvaluation? = try sut.evaluate(request: InAppMessage.eligibilityRequest(), context: Evaluators.context(), nextFlow: EvaluationFlow<InAppMessageEligibilityRequest, ExperimentEvaluation>.end())
                }
                    .to(throwError())
            }

            it("evaluate") {
                expect(try sut.evaluate(request: InAppMessage.eligibilityRequest(), context: Evaluators.context(), nextFlow: nextFlow)).to(beIdenticalTo(evaluation))
            }

            it("evaluate nil") {
                expect(try Sut(evaluation: nil).evaluate(request: InAppMessage.eligibilityRequest(), context: Evaluators.context(), nextFlow: nextFlow)).to(beNil())
            }
        }

        describe("PlatformInAppMessageEligibilityFlowEvaluator") {

            let sut: PlatformInAppMessageEligibilityFlowEvaluator = PlatformInAppMessageEligibilityFlowEvaluator()

            it("when inAppMessage does not support ios then ineligible") {
                let inAppMessage = InAppMessage.create(messageContext: InAppMessage.messageContext(platformTypes: []))
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                expect(actual.isEligible) == false
                expect(actual.reason) == DecisionReason.UNSUPPORTED_PLATFORM
            }

            it("when iam supports ios then evaluate next flow") {

                let request = InAppMessage.eligibilityRequest()
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("OverrideInAppMessageEligibilityFlowEvaluator") {

            var userOverrideMatcher: InAppMessageMatcherStub!
            var sut: OverrideInAppMessageEligibilityFlowEvaluator!

            beforeEach {
                userOverrideMatcher = InAppMessageMatcherStub()
                sut = OverrideInAppMessageEligibilityFlowEvaluator(userOverrideMatcher: userOverrideMatcher)
            }

            it("when user is overridden then evaluated as OVERRIDDEN") {
                // given
                userOverrideMatcher.isMatched = true

                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.isEligible) == true
                expect(actual.reason) == DecisionReason.OVERRIDDEN
            }

            it("when user is not overridden then evaluate next flow") {
                // given
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("DraftInAppMessageEligibilityFlowEvaluator") {

            let sut = DraftInAppMessageEligibilityFlowEvaluator()

            it("when inAppMessage is draft then ineligible") {
                // given
                let inAppMessage = InAppMessage.create(status: .draft)
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.isEligible) == false
                expect(actual.reason) == DecisionReason.IN_APP_MESSAGE_DRAFT
            }

            it("when inAppMessage is not draft then evaluate next flow") {
                // given
                let inAppMessage = InAppMessage.create(status: .active)
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("PausedInAppMessageEligibilityFlowEvaluator") {

            let sut = PausedInAppMessageEligibilityFlowEvaluator()

            it("when inAppMessage is pause then ineligible") {
                // given
                let inAppMessage = InAppMessage.create(status: .pause)
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.isEligible) == false
                expect(actual.reason) == DecisionReason.IN_APP_MESSAGE_PAUSED
            }

            it("when inAppMessage is not pause then evaluate next flow") {
                // given
                let inAppMessage = InAppMessage.create(status: .active)
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("PeriodInAppMessageEligibilityFlowEvaluator") {

            let sut = PeriodInAppMessageEligibilityFlowEvaluator()

            it("when timestamp is not in inAppMessage period then ineligible") {
                // given
                let inAppMessage = InAppMessage.create(
                    period: .range(
                        startInclusive: Date(timeIntervalSince1970: 42),
                        endExclusive: Date(timeIntervalSince1970: 100)
                    )
                )
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage, timestamp: Date(timeIntervalSince1970: 100))

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.isEligible) == false
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
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage, timestamp: Date(timeIntervalSince1970: 99))

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("TargetInAppMessageEligibilityFlowEvaluator") {
            var targetMatcher: InAppMessageMatcherStub!
            var sut: TargetInAppMessageEligibilityFlowEvaluator!

            beforeEach {
                targetMatcher = InAppMessageMatcherStub()
                sut = TargetInAppMessageEligibilityFlowEvaluator(targetMatcher: targetMatcher)
            }

            it("when user not in inAppMessage target then evaluated as nil") {
                // given
                targetMatcher.isMatched = false
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.isEligible) == false
                expect(actual.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET
            }

            it("when user in inAppMessage target then evaluate next flow") {
                // given
                targetMatcher.isMatched = true
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("FrequencyCapInAppMessageEligibilityFlowEvaluator") {

            var frequencyCapMatcher: InAppMessageMatcherStub!
            var sut: FrequencyCapInAppMessageEligibilityFlowEvaluator!

            beforeEach {
                frequencyCapMatcher = InAppMessageMatcherStub()
                sut = FrequencyCapInAppMessageEligibilityFlowEvaluator(frequencyCapMatcher: frequencyCapMatcher)
            }

            it("when frequency capped then ineligible") {
                // given
                frequencyCapMatcher.isMatched = true
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.isEligible) == false
                expect(actual.reason) == DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED
            }

            it("when not frequency capped then evaluate next flow") {
                // given
                frequencyCapMatcher.isMatched = false
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("HiddenInAppMessageEligibilityFlowEvaluator") {
            var hiddenMatcher: InAppMessageMatcherStub!
            var sut: HiddenInAppMessageEligibilityFlowEvaluator!

            beforeEach {
                hiddenMatcher = InAppMessageMatcherStub()
                sut = HiddenInAppMessageEligibilityFlowEvaluator(hiddenMatcher: hiddenMatcher)
            }

            it("when user is hidden then eligible") {
                // given
                hiddenMatcher.isMatched = true
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.isEligible) == false
                expect(actual.reason) == DecisionReason.IN_APP_MESSAGE_HIDDEN
            }

            it("when user is not hidden then evaluate next flow") {
                // given
                hiddenMatcher.isMatched = false
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }


        describe("EligibleInAppMessageEligibilityFlowEvaluator") {
            var sut: EligibleInAppMessageEligibilityFlowEvaluator!

            beforeEach {
                sut = EligibleInAppMessageEligibilityFlowEvaluator()
            }

            it("evalaute as eligible") {
                // given
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.isEligible) == true
                expect(actual.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
            }
        }
    }
}

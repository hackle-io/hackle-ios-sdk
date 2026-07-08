import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEligibilityFlowEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var nextFlow: InAppMessageEligibilityLocalEvaluationFlow!
        var evaluation: InAppMessageEligibilityEvaluation!
        var context: EvaluatorContext!

        beforeEach {
            evaluation = InAppMessage.eligibilityEvaluation()
            nextFlow = InAppMessageEligibilityLocalEvaluationFlow.create(evaluation)
            context = Evaluators.context()
        }

        describe("InAppMessageEligibilityFlowEvaluator") {

            let evaluation = InAppMessage.eligibilityEvaluation()

            class Sut: InAppMessageEligibilityFlowEvaluator {
                private let evaluation: InAppMessageEligibilityEvaluation?

                init(evaluation: InAppMessageEligibilityEvaluation?) {
                    self.evaluation = evaluation
                }

                func evaluate(request: InAppMessageEligibilityLocalEvaluateRequest, context: EvaluatorContext, nextFlow: InAppMessageEligibilityLocalEvaluationFlow) throws -> InAppMessageEligibilityEvaluation? {
                    evaluation
                }
            }

            let sut = Sut(evaluation: evaluation)

            it("must be InAppMessageRequest") {
                expect {
                    let _: ExperimentEvaluation? = try sut.evaluate(request: experimentRequest(), context: Evaluators.context(), nextFlow: ExperimentLocalEvaluationFlow.end())
                }
                    .to(throwError())
            }

            it("must be InAppMessageFlow") {
                expect {
                    let _: ExperimentEvaluation? = try sut.evaluate(request: InAppMessage.eligibilityRequest(), context: Evaluators.context(), nextFlow: EvaluationFlow<InAppMessageEligibilityLocalEvaluateRequest, ExperimentEvaluation>.end())
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

        describe("PlatformInAppMessageEligibilityLocalFlowEvaluator") {

            let sut: PlatformInAppMessageEligibilityLocalFlowEvaluator = PlatformInAppMessageEligibilityLocalFlowEvaluator()

            it("when inAppMessage does not support ios then ineligible") {
                let inAppMessage = InAppMessage.create(messageContext: InAppMessage.messageContext(platformTypes: []))
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.UNSUPPORTED_PLATFORM
            }

            it("when iam supports ios then evaluate next flow") {

                let request = InAppMessage.eligibilityRequest()
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("OverrideInAppMessageEligibilityLocalFlowEvaluator") {

            var userOverrideMatcher: InAppMessageMatcherStub!
            var sut: OverrideInAppMessageEligibilityLocalFlowEvaluator!

            beforeEach {
                userOverrideMatcher = InAppMessageMatcherStub()
                sut = OverrideInAppMessageEligibilityLocalFlowEvaluator(userOverrideMatcher: userOverrideMatcher)
            }

            it("when user is overridden then evaluated as OVERRIDDEN") {
                // given
                userOverrideMatcher.isMatched = true

                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == true
                expect(actual.eligibilityResult.reason) == DecisionReason.OVERRIDDEN
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

        describe("DraftInAppMessageEligibilityLocalFlowEvaluator") {

            let sut = DraftInAppMessageEligibilityLocalFlowEvaluator()

            it("when inAppMessage is draft then ineligible") {
                // given
                let inAppMessage = InAppMessage.create(status: .draft)
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_DRAFT
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

        describe("PauseInAppMessageEligibilityLocalFlowEvaluator") {

            let sut = PauseInAppMessageEligibilityLocalFlowEvaluator()

            it("when inAppMessage is pause then ineligible") {
                // given
                let inAppMessage = InAppMessage.create(status: .pause)
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_PAUSED
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
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_PERIOD
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

        describe("TargetInAppMessageEligibilityLocalFlowEvaluator") {
            var targetMatcher: InAppMessageMatcherStub!
            var sut: TargetInAppMessageEligibilityLocalFlowEvaluator!

            beforeEach {
                targetMatcher = InAppMessageMatcherStub()
                sut = TargetInAppMessageEligibilityLocalFlowEvaluator(targetMatcher: targetMatcher)
            }

            it("when user not in inAppMessage target then evaluated as nil") {
                // given
                targetMatcher.isMatched = false
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET
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

        describe("LayoutResolveInAppMessageEligibilityLocalFlowEvaluator") {
            var layoutEvaluator: InAppMessageLayoutLocalEvaluator!
            var sut: LayoutResolveInAppMessageEligibilityLocalFlowEvaluator!

            beforeEach {
                layoutEvaluator = InAppMessageLayoutLocalEvaluator(
                    experimentEvaluator: InAppMessageLayoutExperimentEvaluator(evaluator: DelegatingEvaluator(evaluatorFactory: EvaluatorFactory())),
                    selector: InAppMessageLayoutSelector(),
                    eventRecorder: MockEvaluationEventRecorder()
                )
                sut = LayoutResolveInAppMessageEligibilityLocalFlowEvaluator(layoutEvaluator: layoutEvaluator)
            }

            it("resolve layout") {
                // given
                let request = InAppMessage.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
                expect(context.get(InAppMessageLayoutEvaluateResponse.self)).toNot(beNil())
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
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED
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
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_HIDDEN
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
                expect(actual.eligibilityResult.isEligible) == true
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
            }
        }
    }
}

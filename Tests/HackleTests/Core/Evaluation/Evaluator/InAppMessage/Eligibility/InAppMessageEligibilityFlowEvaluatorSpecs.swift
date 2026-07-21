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
            evaluation = InAppMessageEntity.eligibilityEvaluation()
            nextFlow = InAppMessageEligibilityLocalEvaluationFlow.create(evaluation)
            context = Evaluators.context()
        }

        describe("InAppMessageEligibilityLocalFlowEvaluator") {

            let evaluation = InAppMessageEntity.eligibilityEvaluation()

            class Sut: InAppMessageEligibilityLocalFlowEvaluator {
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
                    let _: ExperimentEvaluation? = try sut.evaluate(request: InAppMessageEntity.eligibilityRequest(), context: Evaluators.context(), nextFlow: EvaluationFlow<InAppMessageEligibilityLocalEvaluateRequest, ExperimentEvaluation>.end())
                }
                    .to(throwError())
            }

            it("evaluate") {
                expect(try sut.evaluate(request: InAppMessageEntity.eligibilityRequest(), context: Evaluators.context(), nextFlow: nextFlow)).to(beIdenticalTo(evaluation))
            }

            it("evaluate nil") {
                expect(try Sut(evaluation: nil).evaluate(request: InAppMessageEntity.eligibilityRequest(), context: Evaluators.context(), nextFlow: nextFlow)).to(beNil())
            }
        }

        describe("PlatformInAppMessageEligibilityFlowEvaluator") {

            let sut = PlatformInAppMessageEligibilityFlowEvaluator()

            it("when inAppMessage does not support ios then ineligible") {
                let inAppMessage = InAppMessageEntity.create(messageContext: InAppMessageEntity.messageContext(platformTypes: []))
                let request = InAppMessageEntity.eligibilityRequest(inAppMessage: inAppMessage)

                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.UNSUPPORTED_PLATFORM
            }

            it("when iam supports ios then evaluate next flow") {

                let request = InAppMessageEntity.eligibilityRequest()
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                expect(actual).to(beIdenticalTo(evaluation))
            }

            it("when platformType is nil then throw") {
                let request = InAppMessageEntity.eligibilityRequest(platformType: nil)

                expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow)).to(throwError(errorType: HackleError.self))
            }
        }

        describe("OverrideInAppMessageEligibilityLocalFlowEvaluator") {

            var sut: OverrideInAppMessageEligibilityLocalFlowEvaluator!

            beforeEach {
                sut = OverrideInAppMessageEligibilityLocalFlowEvaluator(userOverrideMatcher: InAppMessageUserOverrideMatcher())
            }

            it("when user is overridden then evaluated as OVERRIDDEN") {
                // given
                let user = HackleUser.builder().identifier(.user, "a").build()
                let inAppMessage = InAppMessageEntity.create(
                    targetContext: InAppMessageEntity.targetContext(overrides: [
                        InAppMessage.UserOverride(identifierType: "$userId", identifiers: ["a"])
                    ])
                )
                let request = InAppMessageEntity.eligibilityRequest(user: user, inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == true
                expect(actual.eligibilityResult.reason) == DecisionReason.OVERRIDDEN
            }

            it("when user is not overridden then evaluate next flow") {
                // given
                let request = InAppMessageEntity.eligibilityRequest()

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
                let inAppMessage = InAppMessageEntity.create(status: .draft)
                let request = InAppMessageEntity.eligibilityRequest(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_DRAFT
            }

            it("when inAppMessage is not draft then evaluate next flow") {
                // given
                let inAppMessage = InAppMessageEntity.create(status: .active)
                let request = InAppMessageEntity.eligibilityRequest(inAppMessage: inAppMessage)

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
                let inAppMessage = InAppMessageEntity.create(status: .pause)
                let request = InAppMessageEntity.eligibilityRequest(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_PAUSED
            }

            it("when inAppMessage is not pause then evaluate next flow") {
                // given
                let inAppMessage = InAppMessageEntity.create(status: .active)
                let request = InAppMessageEntity.eligibilityRequest(inAppMessage: inAppMessage)

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
                let inAppMessage = InAppMessageEntity.create(
                    period: .range(
                        startInclusive: Date(timeIntervalSince1970: 42),
                        endExclusive: Date(timeIntervalSince1970: 100)
                    )
                )
                let request = InAppMessageEntity.eligibilityRequest(inAppMessage: inAppMessage, timestamp: Date(timeIntervalSince1970: 100))

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_PERIOD
            }

            it("when timestamp is in inAppMeesage period then evaluate next flow") {
                // given
                let inAppMessage = InAppMessageEntity.create(
                    period: .range(
                        startInclusive: Date(timeIntervalSince1970: 42),
                        endExclusive: Date(timeIntervalSince1970: 100)
                    )
                )
                let request = InAppMessageEntity.eligibilityRequest(inAppMessage: inAppMessage, timestamp: Date(timeIntervalSince1970: 99))

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        describe("TargetInAppMessageEligibilityLocalFlowEvaluator") {
            var targetMatcher: TargetMatcherStub!
            var sut: TargetInAppMessageEligibilityLocalFlowEvaluator!
            let target = Target(conditions: [
                Target.Condition(key: Target.Key(type: .userProperty, name: "age"), match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [HackleValue(value: 1)]))
            ])

            beforeEach {
                targetMatcher = TargetMatcherStub.of(false)
                sut = TargetInAppMessageEligibilityLocalFlowEvaluator(targetMatcher: InAppMessageTargetMatcher(targetMatcher: targetMatcher))
            }

            it("when user not in inAppMessage target then evaluated as nil") {
                // given
                let inAppMessage = InAppMessageEntity.create(targetContext: InAppMessageEntity.targetContext(targets: [target]))
                let request = InAppMessageEntity.eligibilityRequest(inAppMessage: inAppMessage)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET
            }

            it("when user in inAppMessage target then evaluate next flow") {
                // given
                targetMatcher.isMatches = [true]
                let inAppMessage = InAppMessageEntity.create(targetContext: InAppMessageEntity.targetContext(targets: [target]))
                let request = InAppMessageEntity.eligibilityRequest(inAppMessage: inAppMessage)

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
                let request = InAppMessageEntity.eligibilityRequest()

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
                let request = InAppMessageEntity.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED
            }

            it("when not frequency capped then evaluate next flow") {
                // given
                frequencyCapMatcher.isMatched = false
                let request = InAppMessageEntity.eligibilityRequest()

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
                let request = InAppMessageEntity.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == false
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_HIDDEN
            }

            it("when user is not hidden then evaluate next flow") {
                // given
                hiddenMatcher.isMatched = false
                let request = InAppMessageEntity.eligibilityRequest()

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
                let request = InAppMessageEntity.eligibilityRequest()

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)!

                // then
                expect(actual.eligibilityResult.isEligible) == true
                expect(actual.eligibilityResult.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
            }
        }
    }
}

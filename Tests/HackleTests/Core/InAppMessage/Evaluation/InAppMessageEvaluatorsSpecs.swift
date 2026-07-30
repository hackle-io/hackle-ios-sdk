import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEvaluatorsSpecs: QuickSpec {
    override class func spec() {

        var evaluateProcessor: EvaluateProcessor!

        beforeEach {
            evaluateProcessor = EvaluateProcessor.create(
                context: HackleCoreContext(),
                clock: SystemClock.shared,
                eventProcessor: MockUserEventProcessor(),
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage.create(suiteName: "iam_evaluators_impression"),
                hiddenStorage: DefaultInAppMessageHiddenStorage.create(suiteName: "iam_evaluators_hidden")
            )
        }

        describe("LOCAL eligibility") {
            it("workspace/inAppMessage 조합으로 InAppMessageEligibilityLocalEvaluateRequest를 조립해 위임한다") {
                let inAppMessage = InAppMessageEntity.create(status: .active)
                let workspace = DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage])
                let user = HackleUser.builder().identifier(.id, "id_1").build()

                let response = try evaluateProcessor.eligibility(
                    workspace: workspace,
                    inAppMessage: inAppMessage,
                    user: user,
                    scope: .trigger,
                    timestamp: Date()
                )

                expect(response.eligibilityEvaluation.inAppMessage.id) == inAppMessage.id
                expect(response.eligibilityEvaluation.eligibilityResult.isEligible) == true
            }

            it("inAppMessage가 ineligible(draft)이면 isEligible false를 반환한다") {
                let inAppMessage = InAppMessageEntity.create(status: .draft)
                let workspace = DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage])
                let user = HackleUser.builder().identifier(.id, "id_1").build()

                let response = try evaluateProcessor.eligibility(
                    workspace: workspace,
                    inAppMessage: inAppMessage,
                    user: user,
                    scope: .trigger,
                    timestamp: Date()
                )

                expect(response.eligibilityEvaluation.inAppMessage.id) == inAppMessage.id
                expect(response.eligibilityEvaluation.eligibilityResult.isEligible) == false
            }
        }

        describe("LOCAL layout") {
            it("workspace/inAppMessage 조합으로 InAppMessageLayoutLocalEvaluateRequest를 조립해 위임한다") {
                let inAppMessage = InAppMessageEntity.create(status: .active)
                let workspace = DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage])
                let user = HackleUser.builder().identifier(.id, "id_1").build()

                let response = try evaluateProcessor.layout(
                    workspace: workspace,
                    inAppMessage: inAppMessage,
                    user: user,
                    scope: .deliver
                )

                expect(response.layoutEvaluation.inAppMessage.id) == inAppMessage.id
                expect(response.layoutEvaluation.layoutResult.message).toNot(beNil())
            }
        }

        describe("REMOTE eligibility") {
            it("서버 평가 결과(isEligible)를 기반으로 평가한다 — record 기본 true") {
                let inAppMessage = inAppMessageEligibilityRemoteResult(id: 400, key: 40, isEligible: true)
                let workspace = MockWorkspaceEvaluation()
                workspace.inAppMessageResults = [inAppMessage]
                let user = HackleUser.builder().identifier(.id, "id_1").build()

                let response = try evaluateProcessor.eligibility(
                    workspace: workspace,
                    inAppMessage: inAppMessage,
                    user: user,
                    scope: .trigger,
                    timestamp: Date()
                )

                expect(response.eligibilityEvaluation.eligibilityResult.isEligible) == true
            }

            it("isEligible이 false인 서버 평가 결과도 그대로 반영한다") {
                let inAppMessage = inAppMessageEligibilityRemoteResult(id: 401, key: 41, isEligible: false)
                let workspace = MockWorkspaceEvaluation()
                workspace.inAppMessageResults = [inAppMessage]
                let user = HackleUser.builder().identifier(.id, "id_1").build()

                let response = try evaluateProcessor.eligibility(
                    workspace: workspace,
                    inAppMessage: inAppMessage,
                    user: user,
                    scope: .trigger,
                    timestamp: Date()
                )

                expect(response.eligibilityEvaluation.eligibilityResult.isEligible) == false
            }
        }

        describe("REMOTE layout") {
            it("layout 결과의 message를 반환한다") {
                let inAppMessage = inAppMessageEligibilityRemoteResult(id: 400, key: 40, isEligible: true)
                let workspace = MockWorkspaceEvaluation()
                workspace.inAppMessageResults = [inAppMessage]
                let user = HackleUser.builder().identifier(.id, "id_1").build()

                let response = try evaluateProcessor.layout(
                    workspace: workspace,
                    inAppMessage: inAppMessage,
                    user: user,
                    scope: .deliver
                )

                expect(response.layoutEvaluation.layoutResult.message).toNot(beNil())
            }
        }

        // MockWorkspaceEvaluation 헬퍼 시그니처가 다르면 Tests/HackleTests/Mock/MockWorkspaceEvaluation.swift의
        // inAppMessageEligibilityRemoteResult/inAppMessageLayoutRemoteResult 팩토리 정의에 맞춘다.
    }
}

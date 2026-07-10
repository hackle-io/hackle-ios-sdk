import Foundation
import Nimble
import Quick

@testable import Hackle

class InAppMessageDeliverLocalEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var workspaceFetcher: MockWorkspaceConfigFetcher!
        var sut: InAppMessageDeliverLocalEvaluator!

        beforeEach {
            workspaceFetcher = MockWorkspaceConfigFetcher()
            let evaluateProcessor = EvaluateProcessor.create(
                context: HackleCoreContext(),
                clock: SystemClock.shared,
                eventProcessor: MockUserEventProcessor(),
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage.create(suiteName: "iam_local_deliver_impression"),
                hiddenStorage: DefaultInAppMessageHiddenStorage.create(suiteName: "iam_local_deliver_hidden")
            )
            sut = InAppMessageDeliverLocalEvaluator(workspaceFetcher: workspaceFetcher, evaluateProcessor: evaluateProcessor)
        }

        it("workspace 없음 -> workspaceNotFound") {
            // given
            every(workspaceFetcher.workspaceMock).returns(nil)

            // when
            let actual = try sut.evaluate(request: InAppMessageEntity.deliverRequest(), user: HackleUser.of(userId: "u"))

            // then
            expect(actual.isEligible) == false
            expect(actual.code) == InAppMessageDeliverResponse.Code.workspaceNotFound
        }

        it("workspace에 해당 key IAM 없음 -> inAppMessageNotFound") {
            // given
            every(workspaceFetcher.workspaceMock).returns(DefaultWorkspaceConfig.create())

            // when
            let actual = try sut.evaluate(request: InAppMessageEntity.deliverRequest(), user: HackleUser.of(userId: "u"))

            // then
            expect(actual.isEligible) == false
            expect(actual.code) == InAppMessageDeliverResponse.Code.inAppMessageNotFound
        }

        it("정상(활성 IAM 픽스처) -> evaluation(eligibility+layout) 포함한 eligible 응답") {
            // given
            let inAppMessage = InAppMessageEntity.create(key: 42)
            every(workspaceFetcher.workspaceMock).returns(DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage]))

            // when
            let actual = try sut.evaluate(request: InAppMessageEntity.deliverRequest(inAppMessageKey: 42), user: HackleUser.of(userId: "u"))

            // then
            expect(actual.isEligible) == true
            expect(actual.code).to(beNil())
            expect(actual.evaluation?.eligibility.eligibilityResult.isEligible) == true
            expect(actual.evaluation?.layout.layoutEvaluation.layoutResult.message).toNot(beNil())
        }

        it("ineligible IAM(draft, atDeliverTime 재평가) -> ineligible 응답 (evaluation nil)") {
            // given
            let inAppMessage = InAppMessageEntity.create(
                key: 42,
                status: .draft,
                evaluateContext: InAppMessageEntity.evaluateContext(atDeliverTime: true)
            )
            every(workspaceFetcher.workspaceMock).returns(DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage]))

            // when
            let actual = try sut.evaluate(request: InAppMessageEntity.deliverRequest(inAppMessageKey: 42), user: HackleUser.of(userId: "u"))

            // then
            expect(actual.isEligible) == false
            expect(actual.code) == InAppMessageDeliverResponse.Code.ineligible
            expect(actual.evaluation).to(beNil())
        }
    }
}

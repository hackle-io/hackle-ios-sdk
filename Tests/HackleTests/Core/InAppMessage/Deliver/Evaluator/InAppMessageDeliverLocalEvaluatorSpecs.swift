import Foundation
import Nimble
import Quick

@testable import Hackle

class InAppMessageDeliverLocalEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var workspaceFetcher: MockWorkspaceConfigFetcher!
        var layoutResolver: MockInAppMessageLayoutResolver!
        var evaluateProcessor: MockInAppMessageEvaluateProcessor!
        var sut: InAppMessageDeliverLocalEvaluator!

        beforeEach {
            workspaceFetcher = MockWorkspaceConfigFetcher()
            layoutResolver = MockInAppMessageLayoutResolver()
            evaluateProcessor = MockInAppMessageEvaluateProcessor()
            sut = InAppMessageDeliverLocalEvaluator(
                workspaceFetcher: workspaceFetcher,
                layoutResolver: layoutResolver,
                evaluateProcessor: evaluateProcessor
            )
        }

        it("workspaceNotFound") {
            // given
            every(workspaceFetcher.workspaceMock).returns(nil)

            // when
            let actual = try sut.evaluate(request: InAppMessageEntity.deliverRequest(), user: HackleUser.of(userId: "u"))

            // then
            expect(actual.isEligible) == false
            expect(actual.code) == InAppMessageDeliverResponse.Code.workspaceNotFound
        }

        it("inAppMessageNotFound") {
            // given
            every(workspaceFetcher.workspaceMock).returns(DefaultWorkspaceConfig.create())

            // when
            let actual = try sut.evaluate(request: InAppMessageEntity.deliverRequest(), user: HackleUser.of(userId: "u"))

            // then
            expect(actual.isEligible) == false
            expect(actual.code) == InAppMessageDeliverResponse.Code.inAppMessageNotFound
        }

        it("ineligible") {
            // given
            let inAppMessage = InAppMessageEntity.create(key: 42)
            every(workspaceFetcher.workspaceMock).returns(DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage]))
            every(layoutResolver.resolveMock).returns(InAppMessageEntity.layoutEvaluateResponse())
            every(evaluateProcessor.processMock).returns(InAppMessageEntity.eligibilityEvaluation(isEligible: false))

            // when
            let actual = try sut.evaluate(request: InAppMessageEntity.deliverRequest(inAppMessageKey: 42), user: HackleUser.of(userId: "u"))

            // then
            expect(actual.isEligible) == false
            expect(actual.code) == InAppMessageDeliverResponse.Code.ineligible
        }

        it("eligible -> evaluation(layout+eligibility) 반환") {
            // given
            let inAppMessage = InAppMessageEntity.create(key: 42)
            every(workspaceFetcher.workspaceMock).returns(DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage]))
            let layout = InAppMessageEntity.layoutEvaluateResponse()
            every(layoutResolver.resolveMock).returns(layout)
            every(evaluateProcessor.processMock).returns(InAppMessageEntity.eligibilityEvaluation(isEligible: true))

            // when
            let actual = try sut.evaluate(request: InAppMessageEntity.deliverRequest(inAppMessageKey: 42), user: HackleUser.of(userId: "u"))

            // then
            expect(actual.isEligible) == true
            expect(actual.code).to(beNil())
            expect(actual.evaluation?.layout).to(beIdenticalTo(layout))
        }

        it("evaluate는 workspaceFetcher/layoutResolver/evaluateProcessor에 위임한다 (seam 경유 동작 불변 회귀)") {
            // given
            let inAppMessage = InAppMessageEntity.create(key: 99)
            let request = InAppMessageEntity.deliverRequest(inAppMessageKey: 99)
            let user = HackleUser.of(userId: "regression-user")
            every(workspaceFetcher.workspaceMock).returns(DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage]))
            let layout = InAppMessageEntity.layoutEvaluateResponse()
            every(layoutResolver.resolveMock).returns(layout)
            let eligibility = InAppMessageEntity.eligibilityEvaluation(isEligible: true)
            every(evaluateProcessor.processMock).returns(eligibility)

            // when
            let actual = try sut.evaluate(request: request, user: user)

            // then
            verify(exactly: 1) {
                workspaceFetcher.workspaceMock
            }
            verify(exactly: 1) {
                layoutResolver.resolveMock
            }
            verify(exactly: 1) {
                evaluateProcessor.processMock
            }
            expect(actual.evaluation?.eligibility).to(beIdenticalTo(eligibility))
            expect(actual.evaluation?.layout).to(beIdenticalTo(layout))
        }
    }
}

import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageDeliverProcessorSpecs: QuickSpec {
    override func spec() {

        var workspaceFetcher: MockWorkspaceFetcher!
        var userManager: MockUserManager!
        var identifierChecker: MockInAppMessageIdentifierChecker!
        var layoutResolver: MockInAppMessageLayoutResolver!
        var evaluateProcessor: MockInAppMessageEvaluateProcessor!
        var presentProcessor: MockInAppMessagePresentProcessor!
        var sut: DefaultInAppMessageDeliverProcessor!
        var sessionManager: MockSessionManager!

        beforeEach {
            workspaceFetcher = MockWorkspaceFetcher()
            userManager = MockUserManager()
            identifierChecker = MockInAppMessageIdentifierChecker()
            layoutResolver = MockInAppMessageLayoutResolver()
            evaluateProcessor = MockInAppMessageEvaluateProcessor()
            presentProcessor = MockInAppMessagePresentProcessor()
            sessionManager = MockSessionManager()
            sut = DefaultInAppMessageDeliverProcessor(
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                userDecoreator: SessionUserDecorator(sessionManager: sessionManager),
                identifierChecker: identifierChecker,
                layoutResolver: layoutResolver,
                evaluateProcessor: evaluateProcessor,
                presentProcessor: presentProcessor
            )
        }

        it("workspaceNotFound") {
            // given
            let request = InAppMessage.deliverRequest()
            every(workspaceFetcher.fetchMock).returns(nil)

            // when
            let actual = sut.process(request: request)

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.workspaceNotFound
        }

        it("inAppMessageNotFound") {
            // given
            let request = InAppMessage.deliverRequest()
            let workspace = WorkspaceEntity.create()
            every(workspaceFetcher.fetchMock).returns(workspace)

            // when
            let actual = sut.process(request: request)

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.inAppMessageNotFound
        }

        it("identifierChanged") {
            // given
            let inAppMessage = InAppMessage.create()
            let request = InAppMessage.deliverRequest()
            let workspace = WorkspaceEntity.create(inAppMessages: [inAppMessage])
            every(workspaceFetcher.fetchMock).returns(workspace)
            every(identifierChecker.isIdentifierChangedMock).returns(true)

            // when
            let actual = sut.process(request: request)

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.identifierChanged
        }

        it("ineligible") {
            // given
            let inAppMessage = InAppMessage.create(
                evaluateContext: InAppMessage.evaluateContext(atDeliverTime: true)
            )
            let request = InAppMessage.deliverRequest(
                reason: DecisionReason.IN_APP_MESSAGE_TARGET
            )
            let workspace = WorkspaceEntity.create(inAppMessages: [inAppMessage])
            every(workspaceFetcher.fetchMock).returns(workspace)
            every(identifierChecker.isIdentifierChangedMock).returns(false)

            let layoutEvaluation = InAppMessage.layoutEvaluation()
            every(layoutResolver.resolveMock).returns(layoutEvaluation)

            let eligibilityEvaluation = InAppMessage.eligibilityEvaluation(isEligible: false)
            every(evaluateProcessor.processMock).returns(eligibilityEvaluation)

            // when
            let actual = sut.process(request: request)

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.ineligible
        }

        it("present") {
            // given
            let inAppMessage = InAppMessage.create(
                key: 42,
                evaluateContext: InAppMessage.evaluateContext(atDeliverTime: false)
            )
            let request = InAppMessage.deliverRequest(
                dispatchId: "111",
                inAppMessageKey: 42,
                reason: DecisionReason.IN_APP_MESSAGE_TARGET
            )
            let workspace = WorkspaceEntity.create(inAppMessages: [inAppMessage])
            every(workspaceFetcher.fetchMock).returns(workspace)
            every(identifierChecker.isIdentifierChangedMock).returns(false)

            let layoutEvaluation = InAppMessage.layoutEvaluation()
            every(layoutResolver.resolveMock).returns(layoutEvaluation)

            let eligibilityEvaluation = InAppMessage.eligibilityEvaluation(isEligible: true)
            every(evaluateProcessor.processMock).returns(eligibilityEvaluation)

            let presentResponse = InAppMessage.presentResponse()
            every(presentProcessor.processMock).returns(presentResponse)

            // when
            let actual = sut.process(request: request)

            // then
            expect(actual.dispatchId) == "111"
            expect(actual.inAppMessageKey) == 42
            expect(actual.code) == InAppMessageDeliverResponse.Code.present
            expect(actual.presentResponse).to(beIdenticalTo(presentResponse))
        }

        it("exception") {
            // given
            let inAppMessage = InAppMessage.create(
                key: 42,
                evaluateContext: InAppMessage.evaluateContext(atDeliverTime: false)
            )
            let request = InAppMessage.deliverRequest(
                dispatchId: "111",
                inAppMessageKey: 42,
                reason: DecisionReason.IN_APP_MESSAGE_TARGET
            )
            let workspace = WorkspaceEntity.create(inAppMessages: [inAppMessage])
            every(workspaceFetcher.fetchMock).returns(workspace)
            every(identifierChecker.isIdentifierChangedMock).returns(false)

            let layoutEvaluation = InAppMessage.layoutEvaluation()
            every(layoutResolver.resolveMock).returns(layoutEvaluation)

            let eligibilityEvaluation = InAppMessage.eligibilityEvaluation(isEligible: true)
            every(evaluateProcessor.processMock).returns(eligibilityEvaluation)

            every(presentProcessor.processMock).answers { _ in
                throw HackleError.error("fail")
            }

            // when
            let actual = sut.process(request: request)

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.exception
        }

        it("userDecorator_injects_session_into_user_context_when_session_exists") {
            // given
            let inAppMessage = InAppMessage.create(
                key: 300,
                evaluateContext: InAppMessage.evaluateContext(atDeliverTime: false)
            )
            let request = InAppMessage.deliverRequest(
                dispatchId: "sess-deco-1",
                inAppMessageKey: 300,
                reason: DecisionReason.IN_APP_MESSAGE_TARGET
            )
            let workspace = WorkspaceEntity.create(inAppMessages: [inAppMessage])
            every(workspaceFetcher.fetchMock).returns(workspace)
            every(identifierChecker.isIdentifierChangedMock).returns(false)

            let layoutEvaluation = InAppMessage.layoutEvaluation()
            every(layoutResolver.resolveMock).returns(layoutEvaluation)

            let eligibilityEvaluation = InAppMessage.eligibilityEvaluation(isEligible: true)
            every(evaluateProcessor.processMock).returns(eligibilityEvaluation)

            var capturedRequest: InAppMessagePresentRequest?
            every(presentProcessor.processMock).answers { args in
                capturedRequest = args
                return InAppMessage.presentResponse()
            }
            let mockSession = Session(id: "0.ffffffff")
            sessionManager.currentSession = mockSession

            // when
            _ = sut.process(request: request)

            expect(capturedRequest).toNot(beNil())
            let user = capturedRequest?.user
            expect(user?.identifiers.keys.contains(IdentifierType.session.rawValue)).to(beTrue())
        }
    }
}

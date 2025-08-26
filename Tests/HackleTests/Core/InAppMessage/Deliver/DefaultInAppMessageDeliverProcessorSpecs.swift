import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageDeliverProcessorSpecs: QuickSpec {
    override func spec() {

        var workspaceFetcher: MockWorkspaceFetcher!
        var userManager: MockUserManager!
        var identifierChecker: MockInAppMessageIdentifierChecker!
        var evaluator: MockInAppMessageEvaluator!
        var presentProcessor: MockInAppMessagePresentProcessor!
        var sut: DefaultInAppMessageDeliverProcessor!

        beforeEach {
            workspaceFetcher = MockWorkspaceFetcher()
            userManager = MockUserManager()
            identifierChecker = MockInAppMessageIdentifierChecker()
            evaluator = MockInAppMessageEvaluator()
            presentProcessor = MockInAppMessagePresentProcessor()
            sut = DefaultInAppMessageDeliverProcessor(
                workspaceFetcher: workspaceFetcher,
                userManager: userManager,
                identifierChecker: identifierChecker,
                evaluator: evaluator,
                presentProcessor: presentProcessor
            )
        }

        it("workspaceNotFound") {
            // given
            let request = InAppMessage.deliverRequest()
            every(workspaceFetcher.fetchMock).returns(nil)

            // when
            let actual = try sut.process(request: request)

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.workspaceNotFound
        }

        it("inAppMessageNotFound") {
            // given
            let request = InAppMessage.deliverRequest()
            let workspace = WorkspaceEntity.create()
            every(workspaceFetcher.fetchMock).returns(workspace)

            // when
            let actual = try sut.process(request: request)

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
            let actual = try sut.process(request: request)

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.identifierChanged
        }

        it("ineligible") {
            // given
            let inAppMessage = InAppMessage.create(
                evaluateContext: InAppMessage.evaluateContext(atDeliverTime: true)
            )
            let request = InAppMessage.deliverRequest(
                evaluation: InAppMessageEvaluation(isEligible: true, reason: DecisionReason.IN_APP_MESSAGE_TARGET)
            )
            let workspace = WorkspaceEntity.create(inAppMessages: [inAppMessage])
            every(workspaceFetcher.fetchMock).returns(workspace)
            every(identifierChecker.isIdentifierChangedMock).returns(false)
            every(evaluator.evaluateMock).returns(InAppMessageEvaluation(isEligible: false, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET))

            // when
            let actual = try sut.process(request: request)

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
                evaluation: InAppMessageEvaluation(isEligible: true, reason: DecisionReason.IN_APP_MESSAGE_TARGET)
            )
            let workspace = WorkspaceEntity.create(inAppMessages: [inAppMessage])
            every(workspaceFetcher.fetchMock).returns(workspace)
            every(identifierChecker.isIdentifierChangedMock).returns(false)

            let presentResponse = InAppMessage.presentResponse()
            every(presentProcessor.processMock).returns(presentResponse)

            // when
            let actual = try sut.process(request: request)

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
                evaluation: InAppMessageEvaluation(isEligible: true, reason: DecisionReason.IN_APP_MESSAGE_TARGET)
            )
            let workspace = WorkspaceEntity.create(inAppMessages: [inAppMessage])
            every(workspaceFetcher.fetchMock).returns(workspace)
            every(identifierChecker.isIdentifierChangedMock).returns(false)

            every(presentProcessor.processMock).answers { _ in
                throw HackleError.error("fail")
            }

            // when
            let actual = try sut.process(request: request)

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.exception
        }
    }
}

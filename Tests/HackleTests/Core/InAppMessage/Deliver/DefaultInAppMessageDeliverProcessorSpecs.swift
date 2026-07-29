import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageDeliverProcessorSpecs: AsyncSpec {
    override class func spec() {

        var userManager: MockUserManager!
        var identifierChecker: MockInAppMessageIdentifierChecker!
        var evaluator: MockInAppMessageDeliverEvaluator!
        var presentProcessor: MockInAppMessagePresentProcessor!
        var sessionManager: MockSessionManager!
        var lifecycleManager: MockApplicationLifecycleManager!
        var sut: DefaultInAppMessageDeliverProcessor!

        beforeEach {
            userManager = MockUserManager()
            identifierChecker = MockInAppMessageIdentifierChecker()
            evaluator = MockInAppMessageDeliverEvaluator()
            presentProcessor = MockInAppMessagePresentProcessor()
            sessionManager = MockSessionManager()
            lifecycleManager = MockApplicationLifecycleManager(currentState: .foreground)
            sut = DefaultInAppMessageDeliverProcessor(
                userManager: userManager,
                userDecorator: SessionUserDecorator(sessionManager: sessionManager),
                identifierChecker: identifierChecker,
                evaluator: evaluator,
                presentProcessor: presentProcessor,
                lifecycleManager: lifecycleManager
            )
        }

        func eligibleResponse(experiment: ExperimentEvaluation? = nil) -> InAppMessageDeliverEvaluateResponse {
            let evaluation = InAppMessageDeliverEvaluation(
                eligibility: InAppMessageEntity.eligibilityEvaluation(isEligible: true),
                layout: InAppMessageEntity.layoutEvaluateResponse(experiment: experiment)
            )
            return InAppMessageDeliverEvaluateResponse.of(evaluation: evaluation)
        }

        it("앱이 foreground가 아니면 applicationNotForeground를 반환하고 평가하지 않는다") {
            // given
            lifecycleManager.currentState = .background
            every(identifierChecker.isIdentifierChangedMock).returns(false)

            // when
            let actual = await sut.process(request: InAppMessageEntity.deliverRequest())

            // then — 평가를 타지 않으므로 노출 이벤트도 기록되지 않는다
            expect(actual.code) == InAppMessageDeliverResponse.Code.applicationNotForeground
            expect(evaluator.evaluateMock.invokations().count) == 0
            expect(presentProcessor.processMock.invokations().count) == 0
        }

        it("identifierChanged") {
            // given
            every(identifierChecker.isIdentifierChangedMock).returns(true)

            // when
            let actual = await sut.process(request: InAppMessageEntity.deliverRequest())

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.identifierChanged
        }

        it("ineligible (evaluator가 ineligible 반환)") {
            // given
            every(identifierChecker.isIdentifierChangedMock).returns(false)
            every(evaluator.evaluateMock).returns(InAppMessageDeliverEvaluateResponse.ineligible(code: .ineligible))

            // when
            let actual = await sut.process(request: InAppMessageEntity.deliverRequest())

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.ineligible
        }

        it("eligible인데 evaluation이 없으면 exception 코드를 반환한다") {
            // given — 내부 불변식 위반 응답
            every(identifierChecker.isIdentifierChangedMock).returns(false)
            every(evaluator.evaluateMock).returns(
                InAppMessageDeliverEvaluateResponse(isEligible: true, code: nil, evaluation: nil)
            )

            // when
            let actual = await sut.process(request: InAppMessageEntity.deliverRequest())

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.exception
        }

        it("workspaceNotFound 코드 전파 (evaluator → response.code)") {
            // given
            every(identifierChecker.isIdentifierChangedMock).returns(false)
            every(evaluator.evaluateMock).returns(InAppMessageDeliverEvaluateResponse.ineligible(code: .workspaceNotFound))

            // when
            let actual = await sut.process(request: InAppMessageEntity.deliverRequest())

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.workspaceNotFound
        }

        it("deliver") {
            // given
            every(identifierChecker.isIdentifierChangedMock).returns(false)
            every(evaluator.evaluateMock).returns(eligibleResponse())
            let presentResponse = InAppMessageEntity.presentResponse()
            every(presentProcessor.processMock).returns(presentResponse)

            // when
            let actual = await sut.process(request: InAppMessageEntity.deliverRequest(dispatchId: "111", inAppMessageKey: 42))

            // then
            expect(actual.dispatchId) == "111"
            expect(actual.inAppMessageKey) == 42
            expect(actual.code) == InAppMessageDeliverResponse.Code.deliver
            expect(actual.presentResponse).to(beIdenticalTo(presentResponse))
        }

        it("when evaluator throws then exception code") {
            // given
            every(identifierChecker.isIdentifierChangedMock).returns(false)
            every(evaluator.evaluateMock).answers { _ in
                throw HackleError.error("fail")
            }

            // when
            let actual = await sut.process(request: InAppMessageEntity.deliverRequest())

            // then
            expect(actual.code) == InAppMessageDeliverResponse.Code.exception
        }

        it("userDecorator_injects_session_into_user_context_when_session_exists") {
            // given
            every(identifierChecker.isIdentifierChangedMock).returns(false)
            every(evaluator.evaluateMock).returns(eligibleResponse())
            var capturedRequest: InAppMessagePresentRequest?
            every(presentProcessor.processMock).answers { args in
                capturedRequest = args
                return InAppMessageEntity.presentResponse()
            }
            let mockSession = Session(id: "0.ffffffff")
            sessionManager.currentSession = mockSession

            // when
            _ = await sut.process(request: InAppMessageEntity.deliverRequest())

            // then
            expect(capturedRequest).toNot(beNil())
            let user = capturedRequest?.user
            expect(user?.identifiers.keys.contains(IdentifierType.session.rawValue)).to(beTrue())
        }

        it("present_request_carries_experiment_properties_when_experiment_backed") {
            // given
            every(identifierChecker.isIdentifierChangedMock).returns(false)
            let experiment = experimentEvaluation(variationId: 320, variationKey: "B")
            every(evaluator.evaluateMock).returns(eligibleResponse(experiment: experiment))
            var capturedRequest: InAppMessagePresentRequest?
            every(presentProcessor.processMock).answers { args in
                capturedRequest = args
                return InAppMessageEntity.presentResponse()
            }

            // when
            _ = await sut.process(request: InAppMessageEntity.deliverRequest())

            // then
            let props = capturedRequest?.properties
            expect(props?["experiment_key"] as? Int64).toNot(beNil())
            expect(props?["variation_id"] as? Int64) == 320
            expect(props?["variation_key"] as? String) == "B"
            expect(props?["experiment_decision_reason"] as? String) == DecisionReason.TRAFFIC_ALLOCATED
        }

        it("present_request_has_no_experiment_properties_when_not_experiment_backed") {
            // given
            every(identifierChecker.isIdentifierChangedMock).returns(false)
            every(evaluator.evaluateMock).returns(eligibleResponse(experiment: nil))
            var capturedRequest: InAppMessagePresentRequest?
            every(presentProcessor.processMock).answers { args in
                capturedRequest = args
                return InAppMessageEntity.presentResponse()
            }

            // when
            _ = await sut.process(request: InAppMessageEntity.deliverRequest())

            // then
            let props = capturedRequest?.properties
            expect(props?["experiment_key"]).to(beNil())
            expect(props?["variation_key"]).to(beNil())
        }
    }
}

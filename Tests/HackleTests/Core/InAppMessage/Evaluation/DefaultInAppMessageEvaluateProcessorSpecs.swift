import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageEvaluateProcessorSpecs: QuickSpec {
    override class func spec() {

        var core: HackleCore!
        var flowFactory: MockInAppMessageEligibilityFlowFactory!
        var eventRecorder: MockEvaluationEventRecorder!
        var sut: DefaultInAppMessageEvaluateProcessor!

        beforeSuite {
            EvaluationContext.shared.register(DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository()))
            EvaluationContext.shared.register(DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()))
        }

        beforeEach {
            core = DefaultHackleCore.create(
                workspaceFetcher: MockWorkspaceFetcher(),
                eventFactory: MockUserEventFactory(),
                eventProcessor: MockUserEventProcessor(),
                manualOverrideStorage: DelegatingManualOverrideStorage(storages: [])
            )
            flowFactory = MockInAppMessageEligibilityFlowFactory()
            eventRecorder = MockEvaluationEventRecorder()
            sut = DefaultInAppMessageEvaluateProcessor(core: core, flowFactory: flowFactory, eventRecorder: eventRecorder)
        }

        it("trigger evaluate") {
            // given
            let request = InAppMessage.eligibilityRequest()
            let evaluation = InAppMessage.eligibilityEvaluation()
            let flow: InAppMessageEligibilityFlow = InAppMessageEligibilityFlow.create(evaluation)
            every(flowFactory.triggerFlowMock).returns(flow)

            // when
            let actual = try sut.process(type: .trigger, request: request)

            // then
            expect(actual as! InAppMessageEligibilityEvaluation).to(beIdenticalTo(evaluation))
            verify(exactly: 1) {
                flowFactory.triggerFlowMock
            }
            verify(exactly: 1) {
                eventRecorder.recordMock
            }
            expect(eventRecorder.recordMock.firstInvokation().arguments.0 as! InAppMessageEligibilityRequest).to(beIdenticalTo(request))
            expect(eventRecorder.recordMock.firstInvokation().arguments.1 as! InAppMessageEligibilityEvaluation).to(beIdenticalTo(evaluation))
        }

        it("deliver evaluate") {
            // given
            let request = InAppMessage.eligibilityRequest()
            let evaluation = InAppMessage.eligibilityEvaluation()
            let flow: InAppMessageEligibilityFlow = InAppMessageEligibilityFlow.create(evaluation)
            every(flowFactory.deliverFlowMock).returns(flow)

            // when
            let actual = try sut.process(type: .deliver, request: request)

            // then
            expect(actual as! InAppMessageEligibilityEvaluation).to(beIdenticalTo(evaluation))
            verify(exactly: 1) {
                flowFactory.deliverFlowMock
            }
            verify(exactly: 1) {
                eventRecorder.recordMock
            }
            expect(eventRecorder.recordMock.firstInvokation().arguments.0 as! InAppMessageEligibilityRequest).to(beIdenticalTo(request))
            expect(eventRecorder.recordMock.firstInvokation().arguments.1 as! InAppMessageEligibilityEvaluation).to(beIdenticalTo(evaluation))
        }
    }
}

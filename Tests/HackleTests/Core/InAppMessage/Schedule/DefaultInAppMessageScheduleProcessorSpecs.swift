import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageScheduleProcessorSpecs: QuickSpec {
    override func spec() {

        var actionDeterminer: MockInAppMessageScheduleActionDeterminer!
        var schedulerFactory: MockInAppMessageSchedulerFactory!
        var scheduler: MockInAppMessageScheduler!
        var sut: DefaultInAppMessageScheduleProcessor!

        beforeEach {
            actionDeterminer = MockInAppMessageScheduleActionDeterminer()
            schedulerFactory = MockInAppMessageSchedulerFactory()
            scheduler = MockInAppMessageScheduler()
            sut = DefaultInAppMessageScheduleProcessor(
                actionDeterminer: actionDeterminer,
                schedulerFactory: schedulerFactory
            )
            every(schedulerFactory.getMock).returns(scheduler)
        }

        it("schedule") {
            // given
            let request = InAppMessage.scheduleRequest()
            let response = InAppMessageScheduleResponse.of(request: request, code: .deliver)
            every(actionDeterminer.determineMock).returns(InAppMessageScheduleAction.deliver)
            every(scheduler.deliverMock).returns(response)

            // when
            let actual = sut.process(request: request)

            // then
            expect(actual).to(beIdenticalTo(response))
        }

        it("exception") {
            // given
            let request = InAppMessage.scheduleRequest()
            every(actionDeterminer.determineMock).returns(InAppMessageScheduleAction.deliver)
            every(scheduler.deliverMock).answers { _ in
                throw HackleError.error("tail")
            }

            // when
            let actual = sut.process(request: request)

            // then
            expect(actual.code) == .exception
        }

        it("onSchedule") {
            // given
            let request = InAppMessage.scheduleRequest()
            let response = InAppMessageScheduleResponse.of(request: request, code: .deliver)
            every(actionDeterminer.determineMock).returns(InAppMessageScheduleAction.deliver)
            every(scheduler.deliverMock).returns(response)

            // when
            sut.onSchedule(request: request)

            // then
            verify(exactly: 1) {
                scheduler.deliverMock
            }
        }
    }
}

import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageScheduleProcessorSpecs: AsyncSpec {
    override class func spec() {

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
            let request = InAppMessageEntity.scheduleRequest()
            let response = InAppMessageScheduleResponse.of(request: request, code: .deliver)
            every(actionDeterminer.determineMock).returns(InAppMessageScheduleAction.deliver)
            every(scheduler.deliverMock).returns(response)

            // when
            let actual = await sut.process(request: request)

            // then
            expect(actual).to(beIdenticalTo(response))
        }

        it("exception") {
            // given
            let request = InAppMessageEntity.scheduleRequest()
            every(actionDeterminer.determineMock).returns(InAppMessageScheduleAction.deliver)
            every(scheduler.deliverMock).answers { _ in
                throw HackleError.error("tail")
            }

            // when
            let actual = await sut.process(request: request)

            // then
            expect(actual.code) == .exception
        }

        it("onSchedule") {
            // given
            let request = InAppMessageEntity.scheduleRequest()
            let response = InAppMessageScheduleResponse.of(request: request, code: .deliver)
            every(actionDeterminer.determineMock).returns(InAppMessageScheduleAction.deliver)
            every(scheduler.deliverMock).returns(response)

            // when
            sut.onSchedule(request: request)

            // then — onSchedule은 Task {}로 발사되므로 toEventually로 완료 대기 (AsyncSpec이므로 async 버전 사용)
            await expect(scheduler.deliverMock.invokations().count).toEventually(equal(1), timeout: .seconds(1))
        }
    }
}

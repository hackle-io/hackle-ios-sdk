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

        it("when deliver throws then process is aborted") {
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

            // then — onSchedule은 processQueue(FIFO)에 비동기 제출하므로 toEventually로 완료 대기 (AsyncSpec이므로 async 버전 사용)
            await expect(scheduler.deliverMock.invokations().count).toEventually(equal(1), timeout: .seconds(1))
        }

        it("processAsync는 FIFO 큐에서 process를 실행한다") {
            // given
            let request = InAppMessageEntity.scheduleRequest()
            let response = InAppMessageScheduleResponse.of(request: request, code: .deliver)
            every(actionDeterminer.determineMock).returns(InAppMessageScheduleAction.deliver)
            every(scheduler.deliverMock).returns(response)

            // when
            sut.processAsync(request: request)

            // then
            await expect(scheduler.deliverMock.invokations().count).toEventually(equal(1), timeout: .seconds(5))
        }

        it("processAsync와 onSchedule 두 진입점의 요청을 하나의 FIFO 큐에서 제출 순서대로 처리한다") {
            // given
            let requestedAt1 = Date(timeIntervalSince1970: 1)
            let requestedAt2 = Date(timeIntervalSince1970: 2)
            let request1 = InAppMessageEntity.scheduleRequest(requetedAt: requestedAt1)
            let request2 = InAppMessageEntity.scheduleRequest(requetedAt: requestedAt2)
            every(actionDeterminer.determineMock).returns(InAppMessageScheduleAction.deliver)
            // 첫 요청의 처리를 느리게 만든다. 직렬화되지 않으면 두 번째 요청이 추월해 순서가 뒤집힌다.
            every(scheduler.deliverMock).answers { request in
                if request.requestedAt == requestedAt1 {
                    Thread.sleep(forTimeInterval: 0.3)
                }
                return InAppMessageScheduleResponse.of(request: request, code: .deliver)
            }

            // when — trigger 경로(processAsync)와 delay 타이머 경로(onSchedule)를 모두 태운다
            sut.processAsync(request: request1)
            sut.onSchedule(request: request2)

            // then — 두 진입점이 같은 큐를 공유하므로 처리 순서는 제출 순서와 같다
            await expect(scheduler.deliverMock.invokations().map { $0.arguments.requestedAt })
                .toEventually(equal([requestedAt1, requestedAt2]), timeout: .seconds(5))
        }
    }
}

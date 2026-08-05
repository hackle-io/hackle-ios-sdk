//
// Created by yong on 2020/12/21.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultUserEventDispatcherSpec: QuickSpec {
    override class func spec() {

        var coreQueue: DispatchQueue!
        var eventRepository: MockSQLiteEventRepository!
        var httpQueue: DispatchQueue!
        var httpClient: MockHttpClient!
        var sut: DefaultUserEventDispatcher!
        var eventEntities: [EventEntity]!
        var eventBackoffController: MockUserEventBackoffController!

        beforeEach {
            coreQueue = DispatchQueue(label: "test.CoreQueue")
            eventRepository = MockSQLiteEventRepository()
            httpQueue = DispatchQueue(label: "test.HttpQueue")
            httpClient = MockHttpClient()
            eventBackoffController = MockUserEventBackoffController()

            eventRepository.deleteAll()

            //every(eventRepository.deleteMock).returns(())
            sut = DefaultUserEventDispatcher(
                eventBaseUrl: URL(string: "localhost")!,
                coreQueue: coreQueue,
                eventRepository: eventRepository,
                httpQueue: httpQueue,
                httpClient: httpClient,
                eventBackoffController: eventBackoffController
            )

            let event = UserEvents.track("test", properties: [:], user: HackleUser(identifiers: [:], properties: [:], hackleProperties: [:]), timestamp: 0)

            eventRepository.save(event: event)
            eventEntities = eventRepository.findAllBy(status: .pending)
            eventRepository.update(events: eventEntities, status: .flushing)

            every(eventBackoffController.checkResponseMock).returns(())
            every(eventBackoffController.isAllowNextFlushMock).returns(true)
        }

        afterEach {
            eventRepository.deleteDatabaseFile()
        }

        func mockResponse(statusCode: Int, error: Error? = nil) -> HttpResponse {
            let url = URL(string: "localhost")!

            return HttpResponse(
                request: HttpRequest.get(url: URL(string: "localhost")!),
                data: nil,
                urlResponse: HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil),
                error: error)
        }

        describe("dispatch") {

            it("이벤트 전송에 실패하면 재시도를 위해 다시 PENDING 상태로 변경한다") {
                // given
                every(httpClient.executeMock).returns(())

                let response = mockResponse(statusCode: 500, error: HackleError.error("error"))

                // when
                sut.dispatch(events: eventEntities)
                httpQueue.sync {
                }

                httpClient.executeMock.firstInvokation().arguments.1(response)
                coreQueue.sync {
                }

                // then
                let count = eventRepository.countBy(status: .pending)
                expect(count) == 1
            }


            it("이벤트 전송에 성공하면 해당 이벤트를 DB에서 지운다") {
                // given
                every(httpClient.executeMock).returns(())

                let response = mockResponse(statusCode: 202)

                // when
                sut.dispatch(events: eventEntities)
                httpQueue.sync {
                }

                httpClient.executeMock.firstInvokation().arguments.1(response)
                coreQueue.sync {
                }

                // then
                let count = eventRepository.count()
                expect(count) == 0
            }

            it("이벤트 전송시 4xx 에러가 발생하면 해당 이벤트를 DB 에서 지운다") {
                // given
                every(httpClient.executeMock).returns(())

                let response = mockResponse(statusCode: 400)

                // when
                sut.dispatch(events: eventEntities)
                httpQueue.sync {
                }

                httpClient.executeMock.firstInvokation().arguments.1(response)
                coreQueue.sync {
                }

                // then
                let count = eventRepository.count()
                expect(count) == 0
            }

            it("이벤트 전송시 5xx 에러가 발생하면 재시도를 위해 다시 PENDING 상태로 변경한다") {
                // given
                every(httpClient.executeMock).returns(())

                let response = mockResponse(statusCode: 500)

                // when
                sut.dispatch(events: eventEntities)
                httpQueue.sync {
                }

                httpClient.executeMock.firstInvokation().arguments.1(response)
                coreQueue.sync {
                }

                // then
                let count = eventRepository.countBy(status: .pending)
                expect(count) == 1
            }
        }
    }
}

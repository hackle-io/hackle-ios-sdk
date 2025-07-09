//
// Created by yong on 2020/12/21.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultUserEventDispatcherSpec: QuickSpec {
    override func spec() {

        var eventQueue: DispatchQueue!
        var eventRepository: MockSQLiteEventRepository!
        var httpQueue: DispatchQueue!
        var httpClient: MockHttpClient!
        var sut: DefaultUserEventDispatcher!
        var eventEntities: [EventEntity]!

        beforeEach {
            eventQueue = DispatchQueue(label: "test.EventQueue")
            eventRepository = MockSQLiteEventRepository()
            httpQueue = DispatchQueue(label: "test.HttpQueue")
            httpClient = MockHttpClient()
            
            eventRepository.deleteAll()

            //every(eventRepository.deleteMock).returns(())
            sut = DefaultUserEventDispatcher(
                eventBaseUrl: URL(string: "localhost")!,
                eventQueue: eventQueue,
                eventRepository: eventRepository,
                httpQueue: httpQueue,
                httpClient: httpClient
            )
            
            let event = UserEvents.track("test", properties: [:], user: HackleUser(identifiers: [:], properties: [:], hackleProperties: [:]), timestamp: 0)
            
            eventRepository.save(event: event)
            eventEntities = eventRepository.findAllBy(status: .pending)
            eventRepository.update(events: eventEntities, status: .flushing)
            
        }

        func mockResponse(statusCode: Int, error: Error? = nil) -> HttpResponse {
            let url = URL(string: "localhost")!

            return HttpResponse(
                request: HttpRequest.get(url: URL(string: "localhost")!),
                data: nil,
                urlResponse: HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil),
                error: error)
        }
        
        describe("delete") {
            beforeEach {
                let calendar = Calendar.current
                let now = Date()
                
                for i in 0..<10 {
                    guard let dateDaysAgo = calendar.date(byAdding: .day, value: -(i), to: now) else { continue }
                    let timestamp = dateDaysAgo.timeIntervalSince1970 + 10000 // add 10 sec
                    let event = UserEvents.track("test\(i)", properties: [:], user: HackleUser(identifiers: [:], properties: [:], hackleProperties: [:]), timestamp: timestamp)
                    eventRepository.save(event: event)
                }
                eventEntities = eventRepository.findAllBy(status: .flushing)
                eventRepository.update(events: eventEntities, status: .pending)
            }
            
            it("7일이 지난 이벤트는 모두 삭제한다") {
                let beforeEvents = eventRepository.getEventToFlush(limit: 20)
                expect(beforeEvents.count) == 11
                eventRepository.update(events: beforeEvents, status: .pending)
                eventRepository.deleteExpiredEvents()
                let events = eventRepository.getEventToFlush(limit: 20)
                expect(events.count) == 8
            }
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
                eventQueue.sync {
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
                eventQueue.sync {
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
                eventQueue.sync {
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
                eventQueue.sync {
                }

                // then
                let count = eventRepository.countBy(status: .pending)
                expect(count) == 1
            }
        }
    }
}

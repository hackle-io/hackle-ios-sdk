import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockEventRepository: Mock, EventRepository {

    lazy var countMock = MockFunction(self, count)

    func count() -> Int {
        call(countMock, args: ())
    }

    lazy var countByMock = MockFunction(self, countBy)

    func countBy(status: EventEntityStatus) -> Int {
        call(countByMock, args: status)
    }

    lazy var saveMock = MockFunction(self, save)

    func save(event: UserEvent) {
        call(saveMock, args: event)
    }

    lazy var getEventToFlushMock = MockFunction(self, getEventToFlush)

    func getEventToFlush(limit: Int) -> [EventEntity] {
        call(getEventToFlushMock, args: limit)
    }

    lazy var findAllByMock = MockFunction(self, findAllBy)

    func findAllBy(status: EventEntityStatus) -> [EventEntity] {
        call(findAllByMock, args: status)
    }

    lazy var updateMock = MockFunction(self, update)

    func update(events: [EventEntity], status: EventEntityStatus) {
        call(updateMock, args: (events, status))
    }

    lazy var deleteMock = MockFunction(self, delete)

    func delete(events: [EventEntity]) {
        call(deleteMock, args: events)
    }

    lazy var deleteOldEventsMock = MockFunction(self, deleteOldEvents)

    func deleteOldEvents(count: Int) {
        call(deleteOldEventsMock, args: count)
    }
}

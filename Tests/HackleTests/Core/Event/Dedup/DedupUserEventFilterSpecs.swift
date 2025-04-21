import Foundation
import Quick
import Nimble
@testable import Hackle

class DedupUserEventFilterSpecs: QuickSpec {
    override func spec() {

        var eventDedupDeterminer: MockUserEventDedupDeterminer!
        var sut: DedupUserEventFilter!

        beforeEach {
            eventDedupDeterminer = MockUserEventDedupDeterminer()
            sut = DedupUserEventFilter(eventDedupDeterminer: eventDedupDeterminer)
        }

        it("when event is dedup target then block") {
            // given
            every(eventDedupDeterminer.isDedupTargetMock).returns(true)

            // when
            let actual = sut.check(event: UserEvents.track("test"))

            // then
            expect(actual).to(equal(UserEventFilterResult.block))
        }

        it("when event is not dedup target then block") {
            // given
            every(eventDedupDeterminer.isDedupTargetMock).returns(false)

            // when
            let actual = sut.check(event: UserEvents.track("test"))

            // then
            expect(actual).to(equal(UserEventFilterResult.pass))
        }
        
        it("dedup filter return not filtered event") {
            // given
            every(eventDedupDeterminer.isDedupTargetMock).returns(true)
            let event = UserEvents.track("test", user: HackleUser
                .builder()
                .properties(["key": "value"])
                .hackleProperties(["hackleKey": "hackleValue"])
                .build()
            )
            
            // when
            let actual = sut.filter(event: event)
            // then
            expect(actual.user).to(beIdenticalTo(event.user))
            expect(actual.timestamp).to(equal(event.timestamp))
            expect(actual.type).to(equal(event.type))
            expect(actual.insertId).to(equal(event.insertId))
        }
    }
}


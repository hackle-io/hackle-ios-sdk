import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class PropertiesEventTrackerSpecs: QuickSpec {
    override class func spec() {
        var core: MockHackleCore!
        var eventProcessor: MockUserEventProcessor!
        var userManager: MockUserManager!
        var sut: PropertiesEventTracker!

        beforeEach {
            core = MockHackleCore()
            eventProcessor = MockUserEventProcessor()
            userManager = MockUserManager()
            every(userManager.hackleUserMock).answers { user, hackleAppContext in
                HackleUser.of(user: user, hackleProperties: [:])
            }
            sut = PropertiesEventTracker(core: core, eventProcessor: eventProcessor, userManager: userManager)
        }

        it("onUserUpdated는 아무것도 하지 않는다") {
            sut.onUserUpdated(oldUser: User.builder().build(), newUser: User.builder().build(), timestamp: Date())
            verify(exactly: 0) {
                core.trackMock
            }
            verify(exactly: 0) {
                eventProcessor.flushMock
            }
        }

        it("onPropertyOperations 시 $properties 이벤트를 track하고 flush한다") {
            let user = User.builder().userId("user_id").build()
            let operations = PropertyOperations.builder().set("age", 42).build()
            let timestamp = Date(timeIntervalSince1970: 42)

            sut.onPropertyOperations(user: user, operations: operations, timestamp: timestamp)

            verify(exactly: 1) {
                core.trackMock
            }
            let (event, hackleUser, ts) = core.trackMock.firstInvokation().arguments
            expect(event.key) == "$properties"
            expect(event.properties?["$set"] as? [String: Int]) == ["age": 42]
            expect(hackleUser.identifiers["$userId"]) == "user_id"
            expect(ts) == timestamp
            verify(exactly: 1) {
                eventProcessor.flushMock
            }
        }

        it("clearAll도 동일 경로로 track한다") {
            sut.onPropertyOperations(user: User.builder().build(), operations: PropertyOperations.clearAll(), timestamp: Date())

            verify(exactly: 1) {
                core.trackMock
            }
            let event = core.trackMock.firstInvokation().arguments.0
            expect(event.key) == "$properties"
            expect(event.properties?["$clearAll"]).notTo(beNil())
            verify(exactly: 1) {
                eventProcessor.flushMock
            }
        }
    }
}

import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageManagerSpecs: QuickSpec {
    override func spec() {

        var triggerProcessor: MockInAppMessageTriggerProcessor!
        var resetProcessor: MockInAppMessageResetProcessor!
        var sut: InAppMessageManager!

        beforeEach {
            triggerProcessor = MockInAppMessageTriggerProcessor()
            resetProcessor = MockInAppMessageResetProcessor()
            sut = InAppMessageManager(triggerProcessor: triggerProcessor, resetProcessor: resetProcessor)
        }

        it("onEvent") {
            // given
            let event = UserEvents.track("test")

            // when
            sut.onEvent(event: event)

            // then
            verify(exactly: 1) {
                triggerProcessor.processMock
            }
        }
        it("onUserUpdated") {
            // given
            let oldUser = User.builder().deviceId("1").build()
            let newUser = User.builder().deviceId("2").build()

            // when
            sut.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: Date())

            // then
            verify(exactly: 1) {
                resetProcessor.processMock
            }
        }
    }
}

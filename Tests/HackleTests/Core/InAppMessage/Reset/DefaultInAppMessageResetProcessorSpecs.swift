import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageResetProcessorSpecs: QuickSpec {
    override func spec() {

        var identifierChecker: MockInAppMessageIdentifierChecker!
        var delayManager: MockInAppMessageDelayManager!
        var sut: DefaultInAppMessageResetProcessor!

        beforeEach {
            identifierChecker = MockInAppMessageIdentifierChecker()
            delayManager = MockInAppMessageDelayManager()
            sut = DefaultInAppMessageResetProcessor(identifierChecker: identifierChecker, delayManager: delayManager)
        }

        it("when identifier changed then reset") {
            // given
            let oldUser = User.builder().deviceId("a").build()
            let newUser = User.builder().deviceId("b").build()
            every(identifierChecker.isIdentifierChangedMock).returns(true)
            every(delayManager.cancelAllMock).returns([])

            // when
            sut.process(oldUser: oldUser, newUser: newUser)

            // then
            verify(exactly: 1) {
                delayManager.cancelAllMock
            }
        }

        it("when identifier not changed then do not reset") {
            // given
            let oldUser = User.builder().deviceId("a").build()
            let newUser = User.builder().deviceId("a").build()
            every(identifierChecker.isIdentifierChangedMock).returns(false)

            // when
            sut.process(oldUser: oldUser, newUser: newUser)

            // then
            verify(exactly: 0) {
                delayManager.cancelAllMock
            }
        }
    }
}

import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultPushTokenRegistrySpecs: QuickSpec {
    override func spec() {
        it("register") {
            let sut = DefaultPushTokenRegistry()
            let listener = MockPushTokenListener()
            sut.addListener(listener: listener)

            expect(sut.currentToken()).to(beNil())

            let token = PushToken(platformType: .ios, providerType: .apn, value: "token")
            sut.register(token: token, timestamp: Date(timeIntervalSince1970: 42))
            expect(sut.currentToken()) == token
            verify(exactly: 1) {
                listener.onTokenRegisteredMock
            }

            sut.register(token: token, timestamp: Date(timeIntervalSince1970: 42))
            expect(sut.currentToken()) == token
            verify(exactly: 1) {
                listener.onTokenRegisteredMock
            }

            let token2 = PushToken(platformType: .ios, providerType: .apn, value: "new_token")
            sut.register(token: token2, timestamp: Date(timeIntervalSince1970: 43))
            expect(sut.currentToken()) == token2
            verify(exactly: 2) {
                listener.onTokenRegisteredMock
            }
        }

        it("flush") {
            let sut = DefaultPushTokenRegistry()
            let listener = MockPushTokenListener()
            sut.addListener(listener: listener)

            sut.flush()
            verify(exactly: 0) {
                listener.onTokenRegisteredMock
            }

            let token = PushToken(platformType: .ios, providerType: .apn, value: "token")
            sut.register(token: token, timestamp: Date(timeIntervalSince1970: 42))
            verify(exactly: 1) {
                listener.onTokenRegisteredMock
            }
            expect(listener.onTokenRegisteredMock.firstInvokation().arguments.0) == token

            sut.flush()
            verify(exactly: 2) {
                listener.onTokenRegisteredMock
            }
            expect(listener.onTokenRegisteredMock.invokations()[1].arguments.0) == token
        }
    }
}

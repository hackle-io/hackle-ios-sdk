import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultPushTokenManagerSpecs: QuickSpec {

    override func spec() {
        var repository: MemoryKeyValueRepository!
        var userManager: MockUserManager!
        var eventTracker: MockPushEventTracker!
        var sut: DefaultPushTokenManager!

        beforeEach {
            repository = MemoryKeyValueRepository()
            userManager = MockUserManager()
            eventTracker = MockPushEventTracker()
            sut = DefaultPushTokenManager(repository: repository, userManager: userManager, eventTracker: eventTracker)
        }

        context("currentToken") {
            it("when repository is empty then returns nil") {
                let actual = sut.currentToken()
                expect(actual).to(beNil())
            }

            it("when token stored in repository then returns that token") {
                repository.putString(key: "apns_token", value: "test_token")
                let actual = sut.currentToken()
                expect(actual) == PushToken(platformType: .ios, providerType: .apn, value: "test_token")
            }
        }

        context("onTokenRegistered") {
            it("when current token is nil then register token") {
                // given
                let token = PushToken(platformType: .ios, providerType: .apn, value: "new_token")
                every(userManager.toHackleUserMock).returns(HackleUser.of(userId: "test"))

                // when
                sut.onTokenRegistered(token: token, timestamp: Date(timeIntervalSince1970: 42))

                // then
                expect(repository.getString(key: "apns_token")) == "new_token"
                verify(exactly: 1) {
                    eventTracker.trackPushTokenMock
                }
            }

            it("when current token and new token are difference then register token") {
                // given
                repository.putString(key: "apns_token", value: "current_token")
                every(userManager.toHackleUserMock).returns(HackleUser.of(userId: "test"))
                let token = PushToken(platformType: .ios, providerType: .apn, value: "new_token")

                // when
                sut.onTokenRegistered(token: token, timestamp: Date(timeIntervalSince1970: 42))

                // then
                expect(repository.getString(key: "apns_token")) == "new_token"
                verify(exactly: 1) {
                    eventTracker.trackPushTokenMock
                }
            }

            it("when current token and new token are same then do nothing") {
                // given
                repository.putString(key: "apns_token", value: "token")
                let token = PushToken(platformType: .ios, providerType: .apn, value: "token")

                // when
                sut.onTokenRegistered(token: token, timestamp: Date(timeIntervalSince1970: 42))

                // then
                verify(exactly: 0) {
                    eventTracker.trackPushTokenMock
                }
            }
        }

        context("onSessionStarted") {
            it("when current token is nil then do nothing") {
                sut.onSessionStarted(
                    session: Session.create(timestamp: Date(timeIntervalSince1970: 42)),
                    user: User.builder().deviceId("device").build(),
                    timestamp: Date(timeIntervalSince1970: 42)
                )
                verify(exactly: 0) {
                    eventTracker.trackPushTokenMock
                }
            }

            it("when current token is not nil then register token with new user") {
                // given
                repository.putString(key: "apns_token", value: "token")

                // when
                sut.onSessionStarted(
                    session: Session.create(timestamp: Date(timeIntervalSince1970: 42)),
                    user: User.builder().deviceId("device").build(),
                    timestamp: Date(timeIntervalSince1970: 42)
                )

                // then
                verify(exactly: 1) {
                    eventTracker.trackPushTokenMock
                }
            }
        }
    }
}

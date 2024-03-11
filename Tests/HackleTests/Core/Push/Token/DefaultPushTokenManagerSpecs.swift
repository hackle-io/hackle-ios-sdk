import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultPushTokenManagerSpecs: QuickSpec {

    override func spec() {
        var core: MockHackleCore!
        var repository: MemoryKeyValueRepository!
        var userManager: MockUserManager!
        var sut: DefaultPushTokenManager!

        beforeEach {
            core = MockHackleCore()
            repository = MemoryKeyValueRepository()
            userManager = MockUserManager()
            sut = DefaultPushTokenManager(core: core, repository: repository, userManager: userManager)
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
                    core.trackMock
                }
            }

            it("when current token and new token are same then register token") {
                // given
                repository.putString(key: "apns_token", value: "current_token")
                every(userManager.toHackleUserMock).returns(HackleUser.of(userId: "test"))
                let token = PushToken(platformType: .ios, providerType: .apn, value: "new_token")

                // when
                sut.onTokenRegistered(token: token, timestamp: Date(timeIntervalSince1970: 42))

                // then
                expect(repository.getString(key: "apns_token")) == "new_token"
                verify(exactly: 1) {
                    core.trackMock
                }
            }

            it("when current token and new token then do nothing") {
                // given
                repository.putString(key: "apns_token", value: "token")
                let token = PushToken(platformType: .ios, providerType: .apn, value: "token")

                // when
                sut.onTokenRegistered(token: token, timestamp: Date(timeIntervalSince1970: 42))

                // then
                verify(exactly: 0) {
                    core.trackMock
                }
            }
        }

        context("onUserUpdated") {
            it("when current token is nil then do nothing") {
                sut.onUserUpdated(
                    oldUser: User.builder().deviceId("old").build(),
                    newUser: User.builder().deviceId("new").build(),
                    timestamp: Date(timeIntervalSince1970: 42)
                )
                verify(exactly: 0) {
                    core.trackMock
                }
            }

            it("when current token is not nil then register token with new user") {
                // given
                repository.putString(key: "apns_token", value: "token")
                every(userManager.toHackleUserMock).returns(HackleUser.of(userId: "test"))

                // when
                sut.onUserUpdated(
                    oldUser: User.builder().deviceId("old").build(),
                    newUser: User.builder().deviceId("new").build(),
                    timestamp: Date(timeIntervalSince1970: 42)
                )

                // then
                expect(userManager.toHackleUserMock.firstInvokation().arguments.deviceId) == "new"
                verify(exactly: 1) {
                    core.trackMock
                }
            }
        }
    }
}
import Foundation
import UIKit
import MockingKit
@testable import Hackle

class MockUserManager: Mock, UserManager, @unchecked Sendable {

    var currentUser: User
    var lastHackleAppContext: HackleAppContext? = nil

    init(currentUser: User = HackleUserBuilder().build()) {
        self.currentUser = currentUser
        super.init()

        every(hackleUserMock).answers { user, hackleAppContext in
            HackleUser.of(user: user, hackleProperties: [:])
                .toBuilder()
                .hackleProperties(hackleAppContext.browserProperties)
                .build()
        }
    }

    func addListener(listener: UserListener) {
    }

    lazy var initializeMock = MockFunction(self, initialize)
    func initialize(user: User?) {
        call(initializeMock, args: user)
    }

    // 기본 동작: 현재 유저 기반 HackleUser 반환 (기존 resolveMock 기본값과 동일하게 HackleUser.of 사용)
    lazy var hackleUserMock = MockFunction(self, hackleUser as (User, HackleAppContext) -> HackleUser)
    func hackleUser(user: User, appContext: HackleAppContext) -> HackleUser {
        lastHackleAppContext = appContext
        return call(hackleUserMock, args: (user, appContext))
    }

    // mutator는 mutation을 동기적으로 수행(currentUser 갱신 + call)한 뒤 네트워크 sync용 Task를 반환한다.
    // 동기 프리픽스 계약을 반영 — 반환된 Task를 await하지 않아도 currentUser는 즉시 갱신된다.
    lazy var setUserMock = MockFunction(self, setUserStub)
    private func setUserStub(user: User) {
    }
    func setUser(user: User) -> Task<Void, Never> {
        currentUser = user
        call(setUserMock, args: user)
        return Task {}
    }

    lazy var setUserIdMock = MockFunction(self, setUserIdStub)
    private func setUserIdStub(userId: String?) {
    }
    func setUserId(userId: String?) -> Task<Void, Never> {
        currentUser = currentUser.toBuilder().userId(userId).build()
        call(setUserIdMock, args: userId)
        return Task {}
    }

    lazy var setDeviceIdMock = MockFunction(self, setDeviceIdStub)
    private func setDeviceIdStub(deviceId: String) {
    }
    func setDeviceId(deviceId: String) -> Task<Void, Never> {
        currentUser = currentUser.toBuilder().deviceId(deviceId).build()
        call(setDeviceIdMock, args: deviceId)
        return Task {}
    }

    lazy var resetUserMock = MockFunction(self, resetUserStub)
    private func resetUserStub() {
    }
    func resetUser() -> Task<Void, Never> {
        currentUser = User.builder().build()
        call(resetUserMock, args: ())
        return Task {}
    }

    lazy var updatePropertiesMock = MockFunction(self, updatePropertiesStub)
    private func updatePropertiesStub(operations: PropertyOperations) {
    }
    func updateProperties(operations: PropertyOperations) -> Task<Void, Never> {
        currentUser = currentUser.toBuilder().properties(operations.operate(base: [:])).build()
        call(updatePropertiesMock, args: operations)
        return Task {}
    }

    lazy var syncMock = MockFunction.throwable(self, syncStub)

    private func syncStub() throws {
    }

    func sync() async throws {
        try call(syncMock, args: ())
    }

    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
    }

    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
    }
}

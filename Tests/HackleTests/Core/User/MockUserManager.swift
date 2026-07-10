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

    // MockFunction/MockReference는 동기 함수 타입만 받는다 — async 프로토콜 메서드는 기존 sync()/syncStub와
    // 동일하게 "이름 없는 sync 스텁"을 레퍼런스로 쓰고, 실제 async 구현에서 call()로 위임한다.
    lazy var setUserMock = MockFunction(self, setUserStub)
    private func setUserStub(user: User) {
    }
    func setUser(user: User) async {
        currentUser = user
        call(setUserMock, args: user)
    }

    lazy var setUserIdMock = MockFunction(self, setUserIdStub)
    private func setUserIdStub(userId: String?) {
    }
    func setUserId(userId: String?) async {
        currentUser = currentUser.toBuilder().userId(userId).build()
        call(setUserIdMock, args: userId)
    }

    lazy var setDeviceIdMock = MockFunction(self, setDeviceIdStub)
    private func setDeviceIdStub(deviceId: String) {
    }
    func setDeviceId(deviceId: String) async {
        currentUser = currentUser.toBuilder().deviceId(deviceId).build()
        call(setDeviceIdMock, args: deviceId)
    }

    lazy var resetUserMock = MockFunction(self, resetUserStub)
    private func resetUserStub() {
    }
    func resetUser() async {
        currentUser = User.builder().build()
        call(resetUserMock, args: ())
    }

    lazy var updatePropertiesMock = MockFunction(self, updatePropertiesStub)
    private func updatePropertiesStub(operations: PropertyOperations) {
    }
    func updateProperties(operations: PropertyOperations) async {
        currentUser = currentUser.toBuilder().properties(operations.operate(base: [:])).build()
        call(updatePropertiesMock, args: operations)
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

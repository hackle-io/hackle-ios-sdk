import Foundation

protocol UserManager: Synchronizer, ApplicationLifecycleListener {

    var currentUser: User { get }

    func initialize(user: User?)

    func hackleUser(user: User, appContext: HackleAppContext) -> HackleUser

    func setUser(user: User) async

    func resetUser() async

    func setUserId(userId: String?) async

    func setDeviceId(deviceId: String) async

    func updateProperties(operations: PropertyOperations) async

    func addListener(listener: UserListener)
}

// Kotlin 기본 인자 대응 (D7)
extension UserManager {
    func hackleUser() -> HackleUser {
        hackleUser(user: currentUser, appContext: .default)
    }

    func hackleUser(user: User) -> HackleUser {
        hackleUser(user: user, appContext: .default)
    }

    func hackleUser(appContext: HackleAppContext) -> HackleUser {
        hackleUser(user: currentUser, appContext: appContext)
    }
}

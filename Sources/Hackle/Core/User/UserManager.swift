import Foundation

protocol UserManager: Synchronizer, ApplicationLifecycleListener {

    var currentUser: User { get }

    func initialize(user: User?)

    func hackleUser(user: User, appContext: HackleAppContext) -> HackleUser

    func setUser(user: User) -> Task<Void, Never>

    func resetUser() -> Task<Void, Never>

    func setUserId(userId: String?) -> Task<Void, Never>

    func setDeviceId(deviceId: String) -> Task<Void, Never>

    func updateProperties(operations: PropertyOperations) -> Task<Void, Never>

    func addListener(listener: UserListener)
}

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

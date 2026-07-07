import Foundation

protocol UserManager: Synchronizer {

    var currentUser: User { get }

    func initialize(user: User?)

    func resolve(user: User?, hackleAppContext: HackleAppContext) -> HackleUser

    func toHackleUser(user: User) -> HackleUser

    @discardableResult
    func setUser(user: User) -> Updated<User>

    @discardableResult
    func setUserId(userId: String?) -> Updated<User>

    @discardableResult
    func setDeviceId(deviceId: String) -> Updated<User>

    @discardableResult
    func updateProperties(operations: PropertyOperations) -> Updated<User>

    @discardableResult
    func resetUser() -> Updated<User>

    func syncIfNeeded(updated: Updated<User>) async
}

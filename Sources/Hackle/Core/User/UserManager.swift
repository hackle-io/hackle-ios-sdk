import Foundation

protocol UserManager: Synchronizer, ApplicationLifecycleListener {

    var currentUser: User { get }

    // 리스너 저장소. iOS UserManager는 protocol이라 저장 프로퍼티를 못 가지므로
    // 각 구현체가 이 프로퍼티 1줄만 선언하고, plumbing은 아래 extension이 제공한다.
    // (android는 ApplicationListenerRegistry<T> base 상속으로 해결)
    // nonmutating set: class 전용 extension(where Self: AnyObject)에서 append 등으로
    // 값을 바꾸려면 setter가 self를 mutable로 요구하지 않아야 한다(컴파일러 제약).
    var userListeners: [UserListener] { get nonmutating set }

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

// 리스너 plumbing 공통 구현. userListeners(get set)를 변형하므로 참조 타입 전용.
// 모든 conformer(Local/Remote UserManager)가 class라 안전하다.
extension UserManager where Self: AnyObject {

    func addListener(listener: UserListener) {
        userListeners.append(listener)
        Log.debug("UserListener added [\(listener)]")
    }

    func publishUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        Log.debug("UserManager.publishUserUpdated()")
        for listener in userListeners {
            listener.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: timestamp)
        }
    }

    func publishPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {
        Log.debug("UserManager.publishPropertyOperations()")
        for listener in userListeners {
            listener.onPropertyOperations(user: user, operations: operations, timestamp: timestamp)
        }
    }
}

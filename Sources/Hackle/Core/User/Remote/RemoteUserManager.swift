import Foundation
import UIKit

class RemoteUserManager: UserManager, @unchecked Sendable {

    private let recursiveLock = RecursiveLock(label: "io.hackle.RemoteUserManager")

    private var userListeners: [UserListener]
    private let clock: Clock
    private let device: Device
    private let bundleInfo: BundleInfo
    private let repository: UserRepository
    private let evaluationManager: WorkspaceEvaluationManager

    private let defaultUser: User
    private var context: RemoteUserContext

    // 초기 sync용 컨텍스트 — sync()가 1회 소비한다.
    private let initSyncContext = AtomicReference<SyncContext?>(value: nil)

    private var currentContext: RemoteUserContext {
        recursiveLock.lock {
            context
        }
    }
    var currentUser: User {
        currentContext.user
    }

    init(
        clock: Clock,
        device: Device,
        bundleInfo: BundleInfo,
        repository: UserRepository,
        evaluationManager: WorkspaceEvaluationManager
    ) {
        self.userListeners = []
        self.clock = clock
        self.device = device
        self.bundleInfo = bundleInfo
        self.repository = repository
        self.evaluationManager = evaluationManager
        self.defaultUser = HackleUserBuilder().deviceId(device.id).build()
        self.context = RemoteUserContext.from(user: defaultUser)
    }

    func addListener(listener: UserListener) {
        userListeners.append(listener)
        Log.debug("UserListener added [\(listener)]")
    }

    // Initialize

    func initialize(user: User?) {
        recursiveLock.lock {
            let initUser = user ?? loadUser() ?? defaultUser
            let initContext = RemoteUserContext.from(user: initUser.with(device: device))
            self.context = initContext
            self.initSyncContext.set(newValue: SyncContext(userContext: initContext, operations: RemoteUserManager.setOperations(properties: initUser.properties)))
        }
        Log.debug("RemoteUserManager initialized [\(currentUser)]")
    }

    private func loadUser() -> User? {
        repository.get()
    }

    private func saveUser(user: User) {
        repository.set(user: user)
    }

    // HackleUser resolve

    func hackleUser(user: User, appContext: HackleAppContext) -> HackleUser {
        HackleUser.builder()
            .identifiers(user.identifiers)
            .identifier(.id, user.id)
            .identifier(.id, device.id, overwrite: false)
            .identifier(.user, user.userId)
            .identifier(.device, user.deviceId)
            .identifier(.device, device.id, overwrite: false)
            .identifier(.hackleDevice, device.id)
            .properties(user.properties)
            .hackleProperties(hackleProperties(appContext: appContext))
            .build()
    }

    private func hackleProperties(appContext: HackleAppContext) -> [String: Any] {
        appContext.browserProperties
            .append(device.properties)
            .append(bundleInfo.properties)
    }

    // Update User
    //
    // 동기 프리픽스 계약: mutator는 mutation(updateContext)을 recursiveLock 아래에서 동기적으로 끝내고,
    // 네트워크 sync(syncIfNeeded)만 Task<Void, Never>로 반환한다.

    func setUser(user: User) -> Task<Void, Never> {
        updateAndSyncIfNeeded(operations: RemoteUserManager.setOperations(properties: user.properties)) { _ in
            RemoteUserContext.from(user: user.with(device: self.device))
        }
    }

    func resetUser() -> Task<Void, Never> {
        updateAndSyncIfNeeded(operations: PropertyOperations.clearAll()) { _ in
            RemoteUserContext.from(user: self.defaultUser)
        }
    }

    func setUserId(userId: String?) -> Task<Void, Never> {
        updateAndSyncIfNeeded { context in
            RemoteUserContext.from(user: context.user.toBuilder().userId(userId).build())
        }
    }

    func setDeviceId(deviceId: String) -> Task<Void, Never> {
        updateAndSyncIfNeeded { context in
            RemoteUserContext.from(user: context.user.toBuilder().deviceId(deviceId).build())
        }
    }

    // remote는 properties를 로컬에 저장하지 않으므로 mutation이 없다.
    // syncContext는 Task 진입 전 동기적으로 캡처한다(currentContext는 lock을 통한 스냅샷).
    func updateProperties(operations: PropertyOperations) -> Task<Void, Never> {
        if operations.count == 0 {
            return Task {}
        }
        let syncContext = SyncContext(userContext: currentContext, operations: operations)
        return Task { await self.sync(context: syncContext) }
    }

    private func updateAndSyncIfNeeded(
        operations: PropertyOperations = PropertyOperations.empty(),
        update: (RemoteUserContext) -> RemoteUserContext
    ) -> Task<Void, Never> {
        let updated = updateContext(update: update)
        let syncContext = SyncContext(userContext: updated.new, operations: operations)
        // evaluationKey 변경 여부를 Task 진입 전에 판단해 Bool만 넘긴다.
        // updated(non-Sendable)를 Task 클로저로 캡처하지 않아 sending 데이터 레이스 경고를 피한다.
        let evaluationKeyChanged = updated.old.evaluationKey != updated.new.evaluationKey
        return Task { await self.syncIfNeeded(evaluationKeyChanged: evaluationKeyChanged, syncContext: syncContext) }
    }

    private func updateContext(update: (RemoteUserContext) -> RemoteUserContext) -> UserUpdated<RemoteUserContext> {
        recursiveLock.lock {
            let old = context
            let new = update(old)
            context = new

            if !old.user.identifierEquals(other: new.user) {
                publishUserUpdated(oldUser: old.user, newUser: new.user, timestamp: clock.now())
            }

            return UserUpdated(old: old, new: new)
        }
    }

    private func publishUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        for listener in userListeners {
            listener.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: timestamp)
        }
    }

    // Sync

    struct SyncContext {
        let userContext: RemoteUserContext
        let operations: PropertyOperations
    }

    // Synchronizer 프로토콜 메서드. initSyncContext를 1회 소비한다.
    func sync() async throws {
        let syncContext = initSyncContext.getAndSet(newValue: nil) ?? SyncContext(userContext: currentContext, operations: PropertyOperations.empty())
        await sync(context: syncContext)
    }

    private func sync(context: SyncContext) async {
        let hackleUser = hackleUser(user: context.userContext.user)
        let evaluationContext = WorkspaceEvaluateContext.of(user: hackleUser, operations: context.operations)
        await evaluationManager.sync(context: evaluationContext)
    }

    private func syncIfNeeded(evaluationKeyChanged: Bool, syncContext: SyncContext) async {
        if syncContext.operations.count > 0 {
            await sync(context: syncContext)
            return
        }
        if evaluationKeyChanged {
            await sync(context: syncContext)
            return
        }
    }

    private static func setOperations(properties: [String: Any]) -> PropertyOperations {
        if properties.isEmpty {
            return PropertyOperations.empty()
        }
        let builder = PropertyOperations.builder()
        for (key, value) in properties {
            builder.set(key, value)
        }
        return builder.build()
    }
}

extension RemoteUserManager: ApplicationLifecycleListener {
    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        // nothing to do
    }

    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        Log.debug("RemoteUserManager.onBackground")
        saveUser(user: currentUser)
    }
}

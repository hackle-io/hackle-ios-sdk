import Foundation
import UIKit

class LocalUserManager: UserManager, @unchecked Sendable {

    private let recursiveLock = RecursiveLock(label: "io.hackle.LocalUserManager")

    var userListeners: [UserListener]
    private let repository: UserRepository
    private let cohortFetcher: UserCohortFetcher
    private let targetFetcher: UserTargetEventFetcher
    private let clock: Clock

    private let device: Device
    private let bundleInfo: BundleInfo
    private let defaultUser: User
    private var context: LocalUserContext

    private var currentContext: LocalUserContext {
        recursiveLock.lock {
            context
        }
    }
    var currentUser: User {
        currentContext.user
    }

    init(device: Device, bundleInfo: BundleInfo, repository: UserRepository, cohortFetcher: UserCohortFetcher, targetFetcher: UserTargetEventFetcher, clock: Clock) {
        self.userListeners = []
        self.repository = repository
        self.cohortFetcher = cohortFetcher
        self.targetFetcher = targetFetcher
        self.clock = clock
        self.device = device
        self.bundleInfo = bundleInfo
        self.defaultUser = HackleUserBuilder().deviceId(device.id).build()
        self.context = LocalUserContext.of(user: defaultUser, cohorts: UserCohorts.empty(), targetEvents: UserTargetEvents.empty())
    }

    func initialize(user: User?) {
        recursiveLock.lock { [weak self] in
            guard let self = self else {
                Log.debug("UserManager instance deallocated")
                return
            }
            let initUser = (user ?? self.loadUser() ?? self.defaultUser)
            self.context = LocalUserContext.of(user: initUser.with(device: device), cohorts: UserCohorts.empty(), targetEvents: UserTargetEvents.empty())
        }
        Log.debug("UserManager initialized [\(currentUser)]")
    }

    // HackleUser resolve

    func hackleUser(user: User, appContext: HackleAppContext) -> HackleUser {
        let context = recursiveLock.lock {
            self.context.with(user: user)
        }
        return toHackleUser(context: context, hackleAppContext: appContext)
    }

    private func toHackleUser(context: LocalUserContext, hackleAppContext: HackleAppContext) -> HackleUser {
        HackleUser.builder()
            .identifiers(context.user.identifiers)
            .identifier(.id, context.user.id)
            .identifier(.id, device.id, overwrite: false)
            .identifier(.user, context.user.userId)
            .identifier(.device, context.user.deviceId)
            .identifier(.device, device.id, overwrite: false)
            .identifier(.hackleDevice, device.id)
            .properties(context.user.properties)
            .hackleProperties(hackleProperties(hackleAppContext: hackleAppContext, device: device, bundleInfo: bundleInfo))
            .cohorts(context.cohorts.rawCohorts)
            .targetEvents(context.targetEvents)
            .build()
    }

    private func hackleProperties(
        hackleAppContext: HackleAppContext, device: Device, bundleInfo: BundleInfo) -> [String: Any] {
            let hackleProperties = hackleAppContext.browserProperties
                .append(device.properties)
                .append(bundleInfo.properties)

        return hackleProperties
    }


    // Sync

    func sync() async throws {
        await sync(user: currentUser, shouldSyncCohort: true, shouldSyncTargetEvent: true)
    }

    private func syncIfNeeded(updated: UserUpdated<LocalUserContext>) async {
        await sync(
            user: updated.new.user,
            shouldSyncCohort: hasNewIdentifiers(previousUser: updated.old.user, currentUser: updated.new.user),
            shouldSyncTargetEvent: !updated.old.user.identifierEquals(other: updated.new.user)
        )
    }

    private func sync(user: User, shouldSyncCohort: Bool, shouldSyncTargetEvent: Bool) async {
        await withTaskGroup(of: Void.self) { group in
            if shouldSyncCohort {
                group.addTask { await self.syncCohort(user: user) }
            }
            if shouldSyncTargetEvent {
                group.addTask { await self.syncTargetEvent(user: user) }
            }
        }
    }

    private func syncCohort(user: User) async {
        do {
            let cohorts = try await cohortFetcher.fetch(user: user)
            recursiveLock.lock {
                context = context.update(cohorts: cohorts)
            }
        } catch {
            Log.error("Cohort sync failed: \(error)")
        }
    }

    private func syncTargetEvent(user: User) async {
        do {
            let targetEvents = try await targetFetcher.fetch(user: user)
            recursiveLock.lock {
                context = context.update(targetEvents: targetEvents)
            }
        } catch {
            Log.error("Target event sync failed: \(error)")
        }
    }

    private func hasNewIdentifiers(previousUser: User, currentUser: User) -> Bool {
        let previousIdentifiers = previousUser.resolvedIdentifiers
        let currentIdentifiers = currentUser.resolvedIdentifiers

        return currentIdentifiers.contains { type, value in
            !previousIdentifiers.contains(type: type, value: value)
        }
    }

    // User update

    // mutation(updateContext)은 lock 안에서 동기적으로 끝난 뒤(= 동기 프리픽스), 네트워크 sync만 Task로 반환한다.
    func setUser(user: User) -> Task<Void, Never> {
        let updated = recursiveLock.lock {
            updateUser(user: user)
        }
        return Task { await self.syncIfNeeded(updated: updated) }
    }

    func setUserId(userId: String?) -> Task<Void, Never> {
        let updated = recursiveLock.lock {
            updateUser(user: context.user.toBuilder().userId(userId).build())
        }
        return Task { await self.syncIfNeeded(updated: updated) }
    }

    func setDeviceId(deviceId: String) -> Task<Void, Never> {
        let updated = recursiveLock.lock {
            updateUser(user: context.user.toBuilder().deviceId(deviceId).build())
        }
        return Task { await self.syncIfNeeded(updated: updated) }
    }

    func resetUser() -> Task<Void, Never> {
        let updated = recursiveLock.lock {
            let updated = updateContext { _ in
                defaultUser
            }
            publishPropertyOperations(user: updated.new.user, operations: PropertyOperations.clearAll(), timestamp: clock.now())
            return updated
        }
        return Task { await self.syncIfNeeded(updated: updated) }
    }

    func updateProperties(operations: PropertyOperations) -> Task<Void, Never> {
        let updated = recursiveLock.lock {
            operateProperties(operations: operations)
        }
        return Task { await self.syncIfNeeded(updated: updated) }
    }

    private func updateUser(user: User) -> UserUpdated<LocalUserContext> {
        updateContext { currentUser in
            user.with(device: device).mergeWith(other: currentUser)
        }
    }

    private func operateProperties(operations: PropertyOperations) -> UserUpdated<LocalUserContext> {
        updateContext { currentUser in
            publishPropertyOperations(user: currentUser, operations: operations, timestamp: clock.now())
            let properties = operations.operate(base: currentUser.properties)
            return currentUser.with(properties: properties)
        }
    }

    private func updateContext(updater: (User) -> User) -> UserUpdated<LocalUserContext> {
        let oldContext = context
        let oldUser = oldContext.user
        let newUser = updater(oldUser)

        let newContext = context.with(user: newUser)
        context = newContext

        if !newUser.identifierEquals(other: oldUser) {
            publishUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: clock.now())
        }

        saveUser(user: newUser)
        return UserUpdated(old: oldContext, new: newContext)
    }

    private func publishPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {
        Log.debug("UserManager.publishPropertyOperations()")
        for listener in userListeners {
            listener.onPropertyOperations(user: user, operations: operations, timestamp: timestamp)
        }
    }

    private func loadUser() -> User? {
        repository.get()
    }

    private func saveUser(user: User) {
        repository.set(user: user)
    }
}

// ApplicationLifecycleListener conformance (UserManager 프로토콜이 상속)
extension LocalUserManager {
    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        // nothing to do
    }

    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        Log.debug("UserManager.onBackground")
        saveUser(user: currentUser)
    }
}

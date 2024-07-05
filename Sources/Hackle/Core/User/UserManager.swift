//
//  UserManager.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation


protocol UserManager: Synchronizer {

    var currentUser: User { get }

    func initialize(user: User?)

    func resolve(user: User?) -> HackleUser

    func toHackleUser(user: User) -> HackleUser

    @discardableResult
    func setUser(user: User) -> User

    @discardableResult
    func setUserId(userId: String?) -> User

    @discardableResult
    func setDeviceId(deviceId: String) -> User

    @discardableResult
    func updateProperties(operations: PropertyOperations) -> User

    @discardableResult
    func resetUser() -> User
}

class DefaultUserManager: UserManager, AppStateListener {

    private static let USER_KEY = "user"
    private let lock = ReadWriteLock(label: "io.hackle.DefaultUserManager")

    private var userListeners: [UserListener]
    private let repository: KeyValueRepository
    private let cohortFetcher: UserCohortFetcher
    private let clock: Clock

    private let device: Device
    private let defaultUser: User
    private var context: UserContext

    private var currentContext: UserContext {
        lock.read {
            context
        }
    }
    var currentUser: User {
        currentContext.user
    }

    init(device: Device, repository: KeyValueRepository, cohortFetcher: UserCohortFetcher, clock: Clock) {
        self.userListeners = []
        self.repository = repository
        self.cohortFetcher = cohortFetcher
        self.clock = clock
        self.device = device
        self.defaultUser = HackleUserBuilder().id(device.id).deviceId(device.id).build()
        self.context = UserContext.of(user: defaultUser, cohorts: UserCohorts.empty())
    }

    func addListener(listener: UserListener) {
        userListeners.append(listener)
        Log.debug("UserListener added [\(listener)]")
    }

    func initialize(user: User?) {
        lock.write { [weak self] in
            let initUser = (user ?? loadUser() ?? defaultUser)
            self?.context = UserContext.of(user: initUser.with(device: device), cohorts: UserCohorts.empty())
        }
        Log.debug("UserManager initialized [\(currentUser)]")
    }

    func resolve(user: User?) -> HackleUser {
        guard let user else {
            return toHackleUser(context: currentContext)
        }

        let context = lock.write {
            updateUser(user: user)
        }
        return toHackleUser(context: context)
    }

    func toHackleUser(user: User) -> HackleUser {
        let context = context.with(user: user)
        return toHackleUser(context: context)
    }

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        sync(user: currentUser, completion: completion)
    }

    private func sync(user: User, completion: @escaping (Result<(), Error>) -> ()) {
        cohortFetcher.fetch(user: user) { [weak self] result in
            guard let self = self else {
                completion(.failure(HackleError.error("Failed to user sync: instance deallocated")))
                return
            }
            self.handle(result: result, completion: completion)
        }
    }

    private func handle(result: Result<UserCohorts, Error>, completion: @escaping (Result<(), Error>) -> ()) {
        switch result {
        case .success(let cohorts):
            lock.write {
                context = context.update(cohorts: cohorts)
            }
            completion(.success(()))
            return
        case .failure(let error):
            completion(.failure(error))
            return
        }
    }

    private func toHackleUser(context: UserContext) -> HackleUser {
        HackleUser.builder()
            .identifiers(context.user.identifiers)
            .identifier(.id, context.user.id)
            .identifier(.id, device.id, overwrite: false)
            .identifier(.user, context.user.userId)
            .identifier(.device, context.user.deviceId)
            .identifier(.device, device.id, overwrite: false)
            .identifier(.hackleDevice, device.id)
            .properties(context.user.properties)
            .hackleProperties(device.properties)
            .cohorts(context.cohorts.rawCohorts)
            .build()
    }

    func setUser(user: User) -> User {
        lock.write {
            updateUser(user: user).user
        }
    }

    func setUserId(userId: String?) -> User {
        lock.write {
            updateUser(user: context.user.toBuilder().userId(userId).build()).user
        }
    }

    func setDeviceId(deviceId: String) -> User {
        lock.write {
            updateUser(user: context.user.toBuilder().deviceId(deviceId).build()).user
        }
    }

    func resetUser() -> User {
        lock.write {
            let context = updateContext { _ in
                defaultUser
            }
            return context.user
        }
    }

    func updateProperties(operations: PropertyOperations) -> User {
        lock.write {
            operateProperties(operations: operations)
        }
    }

    private func updateUser(user: User) -> UserContext {
        updateContext { currentUser in
            user.with(device: device).mergeWith(other: currentUser)
        }
    }

    private func operateProperties(operations: PropertyOperations) -> User {
        let context = updateContext { currentUser in
            let properties = operations.operate(base: currentUser.properties)
            return currentUser.with(properties: properties)
        }
        return context.user
    }

    private func updateContext(updater: (User) -> User) -> UserContext {
        let oldUser = context.user
        let newUser = updater(oldUser)

        let newContext = context.with(user: newUser)
        context = newContext

        if !newUser.identifierEquals(other: oldUser) {
            changeUser(oldUser: oldUser, newUser: newUser, timestamp: Date())
        }

        Log.debug("UserContext updated: \(newContext)")
        return newContext
    }

    private func changeUser(oldUser: User, newUser: User, timestamp: Date) {
        Log.debug("UserManager.publishUserUpdated()")
        for listener in userListeners {
            listener.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: timestamp)
        }
    }

    private func loadUser() -> User? {
        guard let data = repository.getData(key: DefaultUserManager.USER_KEY) else {
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any?] else {
            Log.debug("Failed to deserialize User")
            return nil
        }

        let user = User.from(json: json)
        Log.debug("User loaded: \(user)")
        return user
    }

    private func saveUser(user: User) {
        guard let data = user.toData() else {
            Log.debug("Failed to serialize User.")
            return
        }
        repository.putData(key: DefaultUserManager.USER_KEY, value: data)
        Log.debug("User saved: \(user)")
    }

    func onState(state: AppState, timestamp: Date) {
        Log.debug("UserManager.onState(state: \(state))")
        switch state {
        case .foreground: return
        case .background: saveUser(user: currentUser)
        }
    }
}

private extension User {
    func mergeWith(other: User?) -> User {
        guard let other = other else {
            return self
        }

        if identifierEquals(other: other) {
            return User(
                id: id,
                userId: userId,
                deviceId: deviceId,
                identifiers: identifiers,
                properties: properties.merging(other.properties) { current, _ in
                    current
                }
            )
        }

        return self
    }

    func with(properties: [String: Any]) -> User {
        User(
            id: id,
            userId: userId,
            deviceId: deviceId,
            identifiers: identifiers,
            properties: properties
        )
    }

    func with(device: Device) -> User {
        let builder = toBuilder()
        if id == nil {
            builder.id(device.id)
        }
        if deviceId == nil {
            builder.deviceId(device.id)
        }
        return builder.build()
    }

    func identifierEquals(other: User?) -> Bool {
        guard let other = other else {
            return false
        }
        return userId == other.userId && deviceId == other.deviceId
    }

    func toData() -> Data? {
        let dict: [String: Any?] = [
            "id": id,
            "userId": userId,
            "deviceId": deviceId,
            "identifiers": identifiers,
            "properties": properties
        ]
        return Json.serialize(dict)
    }

    static func from(json: [String: Any?]) -> User {
        User(
            id: json["id"] as? String,
            userId: json["userId"] as? String,
            deviceId: json["deviceId"] as? String,
            identifiers: json["identifiers"] as? [String: String] ?? [:],
            properties: json["properties"] as? [String: Any] ?? [:]
        )
    }
}

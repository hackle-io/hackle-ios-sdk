//
//  UserManager.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation


protocol UserManager {

    var currentUser: User { get }

    func initialize(user: User?)

    @discardableResult
    func setUser(user: User) -> User

    @discardableResult
    func setUserId(userId: String?) -> User

    @discardableResult
    func setDeviceId(deviceId: String) -> User

    @discardableResult
    func setUserProperty(key: String, value: Any?) -> User

    @discardableResult
    func resetUser() -> User
}

class DefaultUserManager: UserManager, AppNotificationListener {

    private static let USER_KEY = "user"

    private let lock = ReadWriteLock(label: "io.hackle.DefaultUserManager")

    private let repository: KeyValueRepository

    private var userListeners: [UserListener]
    private let defaultUser: User

    private var _currentUser: User
    var currentUser: User {
        lock.read {
            _currentUser
        }
    }

    init(device: Device, repository: KeyValueRepository) {
        self.repository = repository
        self.userListeners = []
        self.defaultUser = HackleUserBuilder().deviceId(device.id).build()
        self._currentUser = self.defaultUser
    }

    func addListener(listener: UserListener) {
        userListeners.append(listener)
        Log.debug("UserListener added [\(listener)]")
    }

    func initialize(user: User?) {
        lock.write { [weak self] in
            self?._currentUser = (user ?? loadUser() ?? defaultUser)
        }
        Log.debug("UserManager initialized [\(currentUser)]")
    }

    func setUser(user: User) -> User {
        lock.write {
            updateUser(user: user)
        }
    }

    func setUserId(userId: String?) -> User {
        lock.write {
            updateUser(user: _currentUser.toBuilder().userId(userId).build())
        }
    }

    func setDeviceId(deviceId: String) -> User {
        lock.write {
            updateUser(user: _currentUser.toBuilder().deviceId(deviceId).build())
        }
    }

    func setUserProperty(key: String, value: Any?) -> User {
        lock.write {
            updateUser(user: _currentUser.toBuilder().property(key, value).build())
        }
    }

    func resetUser() -> User {
        lock.write {
            updateUser(user: defaultUser)
        }
    }

    private func updateUser(user: User) -> User {
        let oldUser = _currentUser
        let newUser = user.mergeWith(other: oldUser)
        _currentUser = newUser

        if !newUser.identifierEquals(other: oldUser) {
            changeUser(oldUser: oldUser, newUser: newUser, timestamp: Date())
        }

        Log.debug("User updated: \(_currentUser)")
        return newUser
    }

    private func changeUser(oldUser: User, newUser: User, timestamp: Date) {
        for listener in userListeners {
            listener.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: timestamp)
        }
        Log.debug("User changed")
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

    func onNotified(notification: AppNotification, timestamp: Date) {
        switch notification {
        case .didBecomeActive: return
        case .didEnterBackground: saveUser(user: currentUser)
        }
    }
}

extension User {
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
            properties: json["properties"] as? [String: Any?] ?? [:]
        )
    }
}

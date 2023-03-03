//
// Created by yong on 2020/12/22.
//

import Foundation

@objc public class Hackle: NSObject {

    static let lock = ReadWriteLock(label: "io.hackle.HackleApp")
    static var instance: HackleApp?

    @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT) {
        initialize(sdkKey: sdkKey, user: nil, config: config, completion: {})
    }

    @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT, completion: @escaping () -> ()) {
        initialize(sdkKey: sdkKey, user: nil, config: config, completion: completion)
    }

    @objc public static func initialize(sdkKey: String, user: User?, config: HackleConfig = HackleConfig.DEFAULT) {
        initialize(sdkKey: sdkKey, user: user, config: config, completion: {})
    }

    @objc public static func initialize(sdkKey: String, user: User?, config: HackleConfig = HackleConfig.DEFAULT, completion: @escaping () -> ()) {
        lock.write {
            if instance != nil {
                readyToUse(completion: completion)
            } else {
                let app = HackleApp.create(sdkKey: sdkKey, config: config)
                app.initialize(user: user) {
                    readyToUse(completion: completion)
                }
                instance = app
            }
        }
    }

    private static func readyToUse(completion: () -> ()) {
        Log.info("Hackle SDK ready to use")
        completion()
    }

    ///
    /// Returns a singleton instance of `HackleApp`
    ///
    /// - Returns: The HackleApp instance or `nil` if not initialized
    @objc public static func app() -> HackleApp? {
        lock.write {
            if instance == nil {
                Log.error("HackleApp is not initialized. Make sure to call Hackle.initialize() first")
            }
            return instance
        }
    }
}

extension Hackle {

    @objc public static func user(
        id: String? = nil,
        userId: String? = nil,
        deviceId: String? = nil,
        identifiers: [String: String]? = nil,
        properties: [String: Any]? = nil
    ) -> User {
        User.builder()
            .id(id)
            .userId(userId)
            .deviceId(deviceId)
            .identifiers(identifiers ?? [:])
            .properties(properties ?? [:])
            .build()
    }

    @objc public static func event(key: String, properties: [String: Any]? = nil) -> Event {
        Event.builder(key)
            .properties(properties ?? [:])
            .build()
    }

    @objc public static func event(key: String, value: Double, properties: [String: Any]? = nil) -> Event {
        Event.builder(key)
            .value(value)
            .properties(properties ?? [:])
            .build()
    }
}

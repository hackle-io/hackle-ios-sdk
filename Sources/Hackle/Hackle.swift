//
// Created by yong on 2020/12/22.
//

import Foundation

@objc public class Hackle: NSObject {

    static let lock = ReadWriteLock(label: "io.hackle.HackleApp")
    static var instance: HackleApp?

    ///
    /// Initialized the HackleApp instance
    ///
    /// - Parameters:
    ///   - sdkKey: The Sdk key of your Hackle environment.
    ///   - config: The HackleConfig that contains the desired configuration.
    @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT) {
        lock.write {
            if instance == nil {
                let app = HackleApp.create(sdkKey: sdkKey, config: config)
                app.initialize {
                    readyToUse(completion: {})
                }
                instance = app
            }
        }
    }

    ///
    /// Initialized the HackleApp instance.
    /// When the sdk is ready to use, the callback `completion` is called.
    ///
    /// - Parameters:
    ///   - sdkKey: The Sdk key of your Hackle environment.
    ///   - config: The HackleConfig that contains the desired configuration.
    ///   - completion: Callback that is called when Hackle App is ready to use.
    @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT, completion: @escaping () -> ()) {
        lock.write {
            if instance != nil {
                readyToUse(completion: completion)
            } else {
                let app = HackleApp.create(sdkKey: sdkKey, config: config)
                app.initialize {
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
        User(id: id, userId: userId, deviceId: deviceId, identifiers: identifiers, properties: properties)
    }

    @objc public static func event(key: String, properties: [String: Any]? = nil) -> Event {
        Event(key: key, properties: properties)
    }

    @objc public static func event(key: String, value: Double, properties: [String: Any]? = nil) -> Event {
        Event(key: key, value: value, properties: properties)
    }
}

//
// Created by yong on 2020/12/22.
//

import Foundation

/// The main entry point for the Hackle SDK.
/// 
/// Initialize the SDK once in your application lifecycle using ``initialize(sdkKey:config:)`` or one of its variants,
/// then access the singleton instance through ``app()``.
@objc public class Hackle: NSObject {

    private static let queue = DispatchQueue(label: "io.hackle.InitializeQueue", qos: .utility)
    static let lock = ReadWriteLock(label: "io.hackle.HackleApp")

    private final class AppContainer: @unchecked Sendable {
        var app: HackleApp?
    }

    private static let container = AppContainer()

    /// Initializes the Hackle SDK with the provided SDK key and configuration.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT) {
        initialize(sdkKey: sdkKey, user: nil, config: config, completion: {})
    }

    /// Initializes the Hackle SDK with the provided SDK key, configuration, and completion handler.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    ///   - completion: Completion handler called when initialization is complete
    @preconcurrency @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT, completion: @escaping @Sendable () -> ()) {
        initialize(sdkKey: sdkKey, user: nil, config: config, completion: completion)
    }

    /// Initializes the Hackle SDK with the provided SDK key, user, and configuration.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - user: Initial user to set for the SDK. Can be nil
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    @objc public static func initialize(sdkKey: String, user: User?, config: HackleConfig = HackleConfig.DEFAULT) {
        initialize(sdkKey: sdkKey, user: user, config: config, completion: {})
    }

    /// Initializes the Hackle SDK with the provided SDK key, user, configuration, and completion handler.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - user: Initial user to set for the SDK. Can be nil
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    ///   - completion: Completion handler called when initialization is complete
    @preconcurrency @objc public static func initialize(sdkKey: String, user: User?, config: HackleConfig = HackleConfig.DEFAULT, completion: @escaping @Sendable () -> ()) {
        lock.write {
            if container.app != nil {
                readyToUse(completion: completion)
            } else {
                let app = HackleApp.create(sdkKey: sdkKey, config: config)
                app.initialize(user: user) {
                    readyToUse(completion: completion)
                }
                container.app = app
            }
        }
    }

    private static func readyToUse(completion: @escaping @Sendable () -> ()) {
        queue.async {
            completion()
        }
    }

    /// Returns a singleton instance of ``HackleApp``.
    ///
    /// - Returns: The HackleApp instance or `nil` if not initialized
    @objc public static func app() -> HackleApp? {
        lock.read {
            if container.app == nil {
                Log.error("HackleApp is not initialized. Make sure to call Hackle.initialize() first")
            }
            return container.app
        }
    }
}

// MARK: async initialization
extension Hackle {
    /// Initializes the Hackle SDK and suspends until initialization completes.
    ///
    /// - Parameter sdkKey: Your Hackle SDK key
    public static func initialize(sdkKey: String) async {
        await withCheckedContinuation { continuation in
            initialize(sdkKey: sdkKey, user: nil, config: HackleConfig.DEFAULT) {
                continuation.resume()
            }
        }
    }
    
    /// Initializes the Hackle SDK and suspends until initialization completes.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - user: Initial user to set for the SDK. Can be nil
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    public static func initialize(sdkKey: String, user: User?) async {
        await withCheckedContinuation { continuation in
            initialize(sdkKey: sdkKey, user: user, config: HackleConfig.DEFAULT) {
                continuation.resume()
            }
        }
    }
    
    /// Initializes the Hackle SDK and suspends until initialization completes.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - user: Initial user to set for the SDK. Can be nil
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    public static func initialize(sdkKey: String, config: HackleConfig) async {
        await withCheckedContinuation { continuation in
            initialize(sdkKey: sdkKey, user: nil, config: config) {
                continuation.resume()
            }
        }
    }
    
    /// Initializes the Hackle SDK and suspends until initialization completes.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - user: Initial user to set for the SDK. Can be nil
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    public static func initialize(sdkKey: String, user: User?, config: HackleConfig) async {
        await withCheckedContinuation { continuation in
            initialize(sdkKey: sdkKey, user: user, config: config) {
                continuation.resume()
            }
        }
    }
}

// MARK: convenience
extension Hackle {

    /// Creates a new ``User`` instance with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: User identifier
    ///   - userId: User ID
    ///   - deviceId: Device identifier
    ///   - identifiers: Additional user identifiers
    ///   - properties: User properties
    /// - Returns: A new User instance
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

    /// Creates a new ``Event`` instance with the specified key and properties.
    ///
    /// - Parameters:
    ///   - key: Event key
    ///   - properties: Event properties
    /// - Returns: A new Event instance
    @objc public static func event(key: String, properties: [String: Any]? = nil) -> Event {
        Event.builder(key)
            .properties(properties ?? [:])
            .build()
    }

    /// Creates a new ``Event`` instance with the specified key, value, and properties.
    ///
    /// - Parameters:
    ///   - key: Event key
    ///   - value: Event value
    ///   - properties: Event properties
    /// - Returns: A new Event instance
    @objc public static func event(key: String, value: Double, properties: [String: Any]? = nil) -> Event {
        Event.builder(key)
            .value(value)
            .properties(properties ?? [:])
            .build()
    }
}

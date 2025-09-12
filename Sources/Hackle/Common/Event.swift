//
// Created by yong on 2020/12/11.
//

import Foundation

/// Represents an event to be tracked in Hackle analytics.
@objc(HackleEvent)
public class Event: NSObject {

    let key: String
    let value: Double?
    let properties: [String: Any]?

    init(key: String, value: Double? = nil, properties: [String: Any]? = nil) {
        self.key = key
        self.value = value
        self.properties = properties
    }

    /// Creates a new event builder with the specified key.
    ///
    /// - Parameter key: The event key identifier
    /// - Returns: A ``HackleEventBuilder`` instance for creating events
    @objc public static func builder(_ key: String) -> HackleEventBuilder {
        HackleEventBuilder(key: key)
    }
}

/// Builder for creating ``Event`` instances.
///
/// Use this builder to construct events with specific values and properties for analytics tracking.
@objc public class HackleEventBuilder: NSObject {

    private let key: String
    private var value: Double? = nil
    private var properties: PropertiesBuilder = PropertiesBuilder()

    init(key: String) {
        self.key = key
        super.init()
    }

    /// Sets a numeric value for the event.
    ///
    /// - Parameter value: The numeric value associated with the event
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func value(_ value: Double) -> HackleEventBuilder {
        self.value = value
        return self
    }

    /// Adds a custom property to the event.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The property value
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func property(_ key: String, _ value: Any?) -> HackleEventBuilder {
        self.properties.add(key, value)
        return self
    }

    /// Adds multiple custom properties to the event.
    ///
    /// - Parameter properties: A dictionary of property keys and values
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func properties(_ properties: [String: Any]) -> HackleEventBuilder {
        self.properties.add(properties)
        return self
    }

    /// Builds an ``Event`` instance with the configured values.
    ///
    /// - Returns: A new ``Event`` instance
    @objc public func build() -> Event {
        Event(key: key, value: value, properties: properties.build())
    }
}

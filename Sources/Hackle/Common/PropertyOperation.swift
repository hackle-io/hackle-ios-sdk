//
//  PropertyOperation.swift
//  Hackle
//
//  Created by yong on 2023/05/11.
//

import Foundation

enum PropertyOperation: String {
    case set = "$set"
    case setOnce = "$setOnce"
    case unset = "$unset"
    case increment = "$increment"
    case append = "$append"
    case appendOnce = "$appendOnce"
    case prepend = "$prepend"
    case prependOnce = "$prependOnce"
    case remove = "$remove"
    case clearAll = "$clearAll"
}


/// Represents a collection of user property operations to be applied.
@objc(HacklePropertyOperations)
public class PropertyOperations: NSObject {

    private let operations: [PropertyOperation: [String: Any]]

    var count: Int {
        operations.count
    }

    init(operations: [PropertyOperation: [String: Any]]) {
        self.operations = operations
        super.init()
    }

    func contains(_ operation: PropertyOperation) -> Bool {
        operations[operation] != nil
    }

    func asDictionary() -> [PropertyOperation: [String: Any]] {
        operations
    }

    func toEvent() -> Event {
        let builder = Event.builder("$properties")
        for (operation, properties) in asDictionary() {
            builder.property(operation.rawValue, properties)
        }
        return builder.build()
    }

    private static let EMPTY = PropertyOperations(operations: [:])

    /// Creates a new property operations builder.
    ///
    /// - Returns: A ``PropertyOperationsBuilder`` instance for creating property operations
    @objc public static func builder() -> PropertyOperationsBuilder {
        PropertyOperationsBuilder()
    }

    /// Creates a property operation that clears all user properties.
    ///
    /// - Returns: A ``PropertyOperations`` instance that will clear all properties
    @objc public static func clearAll() -> PropertyOperations {
        builder().clearAll().build()
    }

    /// Returns an empty property operations instance.
    ///
    /// - Returns: An empty ``PropertyOperations`` instance with no operations
    @objc public static func empty() -> PropertyOperations {
        EMPTY
    }
}

/// Builder for creating ``PropertyOperations`` instances with specific operations.
///
/// Use this builder to construct property operations that can modify user properties
/// in various ways including setting, incrementing, appending, and removing values.
@objc public class PropertyOperationsBuilder: NSObject {

    private var operations = [PropertyOperation: PropertiesBuilder]()

    /// Sets a property value, overwriting any existing value.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The value to set
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func set(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .set, key: key, value: value)
        return self
    }

    /// Sets a property value only if the property doesn't already exist.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The value to set
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func setOnce(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .setOnce, key: key, value: value)
        return self
    }

    /// Removes a property from the user.
    ///
    /// - Parameter key: The property key to remove
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func unset(_ key: String) -> PropertyOperationsBuilder {
        add(operation: .unset, key: key, value: "-")
        return self
    }

    /// Increments a numeric property value.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The amount to increment by
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func increment(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .increment, key: key, value: value)
        return self
    }

    /// Appends a value to an array property.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The value to append
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func append(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .append, key: key, value: value)
        return self
    }

    /// Appends a value to an array property only if the value doesn't already exist in the array.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The value to append
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func appendOnce(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .appendOnce, key: key, value: value)
        return self
    }

    /// Prepends a value to the beginning of an array property.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The value to prepend
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func prepend(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .prepend, key: key, value: value)
        return self
    }

    /// Prepends a value to the beginning of an array property only if the value doesn't already exist in the array.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The value to prepend
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func prependOnce(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .prependOnce, key: key, value: value)
        return self
    }

    /// Removes a specific value from an array property.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The value to remove from the array
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func remove(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .remove, key: key, value: value)
        return self
    }

    /// Clears all user properties.
    ///
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func clearAll() -> PropertyOperationsBuilder {
        add(operation: .clearAll, key: "clearAll", value: "-")
        return self
    }

    private func add(operation: PropertyOperation, key: String, value: Any?) {
        if containsKey(key) {
            Log.debug("Property already added. Ignore the operation. [operation=\(operation), key=\(key), value=\(value.orNil)]")
            return
        }
        if let builder = operations[operation] {
            builder.add(key, value)
        } else {
            let builder = PropertiesBuilder()
            builder.add(key, value)
            operations[operation] = builder
        }
    }

    private func containsKey(_ key: String) -> Bool {
        operations.values.contains { it in
            it.contains(key)
        }
    }

    /// Builds a ``PropertyOperations`` instance with the configured operations.
    ///
    /// - Returns: A new ``PropertyOperations`` instance
    @objc public func build() -> PropertyOperations {
        let operations: [PropertyOperation: [String: Any]] = operations.mapValues { builder in
            builder.build()
        }
        return PropertyOperations(operations: operations)
    }
}

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


@objc public class PropertyOperations: NSObject {

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

    @objc public static func builder() -> PropertyOperationsBuilder {
        PropertyOperationsBuilder()
    }

    @objc public static func clearAll() -> PropertyOperations {
        builder().clearAll().build()
    }

    @objc public static func empty() -> PropertyOperations {
        EMPTY
    }
}

@objc public class PropertyOperationsBuilder: NSObject {

    private var operations = [PropertyOperation: PropertiesBuilder]()

    @discardableResult
    @objc public func set(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .set, key: key, value: value)
        return self
    }

    @discardableResult
    @objc public func setOnce(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .setOnce, key: key, value: value)
        return self
    }

    @discardableResult
    @objc public func unset(_ key: String) -> PropertyOperationsBuilder {
        add(operation: .unset, key: key, value: "-")
        return self
    }

    @discardableResult
    @objc public func increment(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .increment, key: key, value: value)
        return self
    }

    @discardableResult
    @objc public func append(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .append, key: key, value: value)
        return self
    }

    @discardableResult
    @objc public func appendOnce(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .appendOnce, key: key, value: value)
        return self
    }

    @discardableResult
    @objc public func prepend(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .prepend, key: key, value: value)
        return self
    }

    @discardableResult
    @objc public func prependOnce(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .prependOnce, key: key, value: value)
        return self
    }

    @discardableResult
    @objc public func remove(_ key: String, _ value: Any?) -> PropertyOperationsBuilder {
        add(operation: .remove, key: key, value: value)
        return self
    }

    @discardableResult
    @objc public func clearAll() -> PropertyOperationsBuilder {
        add(operation: .clearAll, key: "clearAll", value: "-")
        return self
    }

    internal func add(operation: PropertyOperation, key: String, value: Any?) {
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

    @objc public func build() -> PropertyOperations {
        let operations: [PropertyOperation: [String: Any]] = operations.mapValues { builder in
            builder.build()
        }
        return PropertyOperations(operations: operations)
    }
}

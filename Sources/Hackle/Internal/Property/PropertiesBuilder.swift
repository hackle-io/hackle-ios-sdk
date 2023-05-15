//
//  PropertiesBuilder.swift
//  Hackle
//
//  Created by yong on 2022/05/24.
//

import Foundation


class PropertiesBuilder {

    private var properties = [String: Any]()

    private static let SYSTEM_PROPERTY_KEY_PREFIX = "$"
    private static let MAX_PROPERTIES_COUNT = 128
    private static let MAX_PROPERTY_KEY_LENGTH = 128
    private static let MAX_PROPERTY_VALUE_LENGTH = 1024

    @discardableResult
    func add(_ properties: [String: Any?], setOnce: Bool = false) -> PropertiesBuilder {
        for (key, value) in properties {
            add(key, value, setOnce: setOnce)
        }
        return self
    }

    @discardableResult
    func add(_ key: String, _ value: Any?, setOnce: Bool = false) -> PropertiesBuilder {
        if setOnce && properties[key] != nil {
            return self
        }

        if properties.count >= PropertiesBuilder.MAX_PROPERTIES_COUNT {
            return self
        }

        if key.count > PropertiesBuilder.MAX_PROPERTY_KEY_LENGTH {
            return self
        }

        guard let sanitizedValue = sanitize(key: key, value: value) else {
            return self
        }

        properties[key] = sanitizedValue
        return self
    }

    @discardableResult
    func remove(_ key: String) -> PropertiesBuilder {
        properties.removeValue(forKey: key)
        return self
    }

    @discardableResult
    func remove(_ properties: [String: Any]) -> PropertiesBuilder {
        for (key, _) in properties {
            remove(key)
        }
        return self
    }

    @discardableResult
    func compute(_ key: String, _ remapping: (Any?) -> Any?) -> PropertiesBuilder {
        let oldValue = properties[key]
        let newValue = remapping(oldValue)
        if newValue != nil {
            add(key, newValue)
        } else {
            if oldValue != nil || contains(key) {
                remove(key)
            }
        }
        return self
    }

    func contains(_ key: String) -> Bool {
        properties[key] != nil
    }

    private func sanitize(key: String, value: Any?) -> Any? {
        guard let value = value else {
            return nil
        }

        if let array = value as? [Any?] {
            return array.compactMap { it in
                sanitizeArrayElement(element: it)
            }
        }

        if isValidValue(value: value) {
            return value
        }

        if key.hasPrefix(PropertiesBuilder.SYSTEM_PROPERTY_KEY_PREFIX) {
            return value
        }

        return nil
    }

    private func isValidValue(value: Any) -> Bool {
        switch value {
        case let stringValue as String:
            return stringValue.count <= PropertiesBuilder.MAX_PROPERTY_VALUE_LENGTH
        case is Bool:
            return true
        case is Int, is Int8, is Int16, is Int32, is Int64, is Double, is Float:
            return true
        default:
            return false
        }
    }

    private func sanitizeArrayElement(element: Any?) -> Any? {
        guard let value = element else {
            return nil
        }

        if isValidElement(element: value) {
            return value
        } else {
            return nil
        }
    }

    private func isValidElement(element: Any) -> Bool {
        switch element {
        case let value as String:
            return value.count <= PropertiesBuilder.MAX_PROPERTY_VALUE_LENGTH
        case is Int, is Double, is Float:
            return true
        default:
            return false
        }
    }

    func build() -> [String: Any] {
        properties
    }
}

extension Dictionary<String, Any> {
    func toBuilder() -> PropertiesBuilder {
        let builder = PropertiesBuilder()
        builder.add(self)
        return builder
    }
}

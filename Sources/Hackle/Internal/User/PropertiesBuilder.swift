//
//  PropertiesBuilder.swift
//  Hackle
//
//  Created by yong on 2022/05/24.
//

import Foundation


class PropertiesBuilder {

    private var properties = [String: Any]()

    private static let MAX_PROPERTIES_COUNT = 128
    private static let MAX_PROPERTY_KEY_LENGTH = 128
    private static let MAX_PROPERTY_VALUE_LENGTH = 1024

    @discardableResult
    func add(_ properties: [String: Any?]) -> PropertiesBuilder {
        for (key, value) in properties {
            add(key, value)
        }
        return self
    }

    @discardableResult
    func add(_ key: String, _ value: Any?) -> PropertiesBuilder {
        if properties.count >= PropertiesBuilder.MAX_PROPERTIES_COUNT {
            return self
        }

        if key.count > PropertiesBuilder.MAX_PROPERTY_KEY_LENGTH {
            return self
        }

        guard let sanitizedValue = sanitize(value: value) else {
            return self
        }

        properties[key] = sanitizedValue
        return self
    }

    private func sanitize(value: Any?) -> Any? {
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

        return nil
    }

    private func isValid(key: String, value: Any?) -> Bool {

        guard let value = value else {
            return false
        }

        if properties.count >= PropertiesBuilder.MAX_PROPERTIES_COUNT {
            return false
        }

        if key.count > PropertiesBuilder.MAX_PROPERTY_KEY_LENGTH {
            return false
        }

        switch value {
        case let stringValue as String:
            return stringValue.count <= PropertiesBuilder.MAX_PROPERTY_VALUE_LENGTH
        case is Bool:
            return true
        case is Int, is Double, is Float:
            return true
        default:
            return false
        }
    }


    private func isValidValue(value: Any) -> Bool {
        switch value {
        case let stringValue as String:
            return stringValue.count <= PropertiesBuilder.MAX_PROPERTY_VALUE_LENGTH
        case is Bool:
            return true
        case is Int, is Double, is Float:
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

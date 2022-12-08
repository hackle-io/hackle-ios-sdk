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

    func add(properties: [String: Any]?) -> PropertiesBuilder {
        if let properties = properties {
            for (key, value) in properties {
                add(key: key, value: value)
            }
        }
        return self
    }

    func add(key: String, value: Any?) -> PropertiesBuilder {
        if (isValid(key: key, value: value)) {
            properties[key] = value
        }
        return self
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

    func build() -> [String: Any] {
        properties
    }
}
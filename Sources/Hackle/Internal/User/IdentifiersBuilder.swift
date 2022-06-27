//
//  IdentifiersBuilder.swift
//  Hackle
//
//  Created by yong on 2022/05/24.
//

import Foundation


class IdentifiersBuilder {

    private var identifiers = [String: String]()

    private static let MAX_IDENTIFIER_TYPE_LENGTH = 128
    private static let MAX_IDENTIFIER_VALUE_LENGTH = 512

    func add(identifiers: [String: String]?) -> IdentifiersBuilder {
        if let identifiers = identifiers {
            for (key, value) in identifiers {
                add(type: key, value: value)
            }
        }
        return self
    }

    func add(type: IdentifierType, value: String?) -> IdentifiersBuilder {
        add(type: type.rawValue, value: value)
    }

    func add(type: String, value: String?) -> IdentifiersBuilder {
        if let value = value, isValid(type: type, value: value) {
            identifiers[type] = value
        }
        return self
    }

    private func isValid(type: String, value: String) -> Bool {
        if type.count > IdentifiersBuilder.MAX_IDENTIFIER_TYPE_LENGTH {
            return false
        }

        if value.count > IdentifiersBuilder.MAX_IDENTIFIER_VALUE_LENGTH {
            return false
        }

        if value.isEmpty {
            return false
        }

        return true
    }

    func build() -> [String: String] {
        identifiers
    }
}
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

    @discardableResult
    func add(_ identifiers: [String: String], overwrite: Bool = true) -> IdentifiersBuilder {
        for (key, value) in identifiers {
            add(key, value, overwrite: overwrite)
        }
        return self
    }

    @discardableResult
    func add(_ type: IdentifierType, _ value: String?, overwrite: Bool = true) -> IdentifiersBuilder {
        add(type.rawValue, value, overwrite: overwrite)
    }

    @discardableResult
    func add(_ type: String, _ value: String?, overwrite: Bool = true) -> IdentifiersBuilder {
        if !overwrite && identifiers[type] != nil {
            return self
        }

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
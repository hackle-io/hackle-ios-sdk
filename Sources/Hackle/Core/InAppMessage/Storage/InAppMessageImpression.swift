//
//  InAppMessageImpression.swift
//  Hackle
//
//  Created by yong on 2023/07/19.
//

import Foundation

/// This class is serialized and deserialized to JSON.
/// Please be careful of field changes.
class InAppMessageImpression: Codable {
    var identifiers: [String: String]
    var timestamp: Double

    init(identifiers: [String: String], timestamp: Double) {
        self.identifiers = identifiers
        self.timestamp = timestamp
    }
}

protocol InAppMessageImpressionStorage {
    func get(inAppMessage: InAppMessage) throws -> [InAppMessageImpression]

    func set(inAppMessage: InAppMessage, impressions: [InAppMessageImpression]) throws
}

class DefaultInAppMessageImpressionStorage: InAppMessageImpressionStorage {

    private let keyValueRepository: KeyValueRepository

    init(keyValueRepository: KeyValueRepository) {
        self.keyValueRepository = keyValueRepository
    }

    static func create(suiteName: String) -> DefaultInAppMessageImpressionStorage {
        DefaultInAppMessageImpressionStorage(keyValueRepository: UserDefaultsKeyValueRepository.of(suiteName: suiteName))
    }

    func get(inAppMessage: InAppMessage) throws -> [InAppMessageImpression] {
        guard let data = keyValueRepository.getData(key: String(inAppMessage.id)) else {
            return []
        }
        return try JSONDecoder().decode([InAppMessageImpression].self, from: data)
    }

    func set(inAppMessage: InAppMessage, impressions: [InAppMessageImpression]) throws {
        let data = try JSONEncoder().encode(impressions)
        keyValueRepository.putData(key: String(inAppMessage.id), value: data)
    }
}

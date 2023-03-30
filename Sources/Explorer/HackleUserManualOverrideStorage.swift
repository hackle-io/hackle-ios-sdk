//
//  HackleUserManualOverrideStorage.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import Foundation


class HackleUserManualOverrideStorage: ManualOverrideStorage {

    private let keyValueRepository: KeyValueRepository

    init(keyValueRepository: KeyValueRepository) {
        self.keyValueRepository = keyValueRepository
    }

    static func create(suiteName: String) -> HackleUserManualOverrideStorage {
        HackleUserManualOverrideStorage(keyValueRepository: UserDefaultsKeyValueRepository.of(suiteName: suiteName))
    }

    func get(experiment: Experiment, user: HackleUser) -> Variation? {
        guard let variationId = get(experiment: experiment) else {
            return nil
        }
        return experiment.getVariationOrNil(variationId: variationId)
    }

    func getAll() -> [Int64: Int64] {
        var results: [Int64: Int64] = [:]
        for e in keyValueRepository.getAll() {
            guard let experimentId = Int64(e.key) else {
                continue
            }
            guard let variationId = e.value as? Int else {
                continue
            }
            results[experimentId] = Int64(variationId)
        }
        return results
    }

    func get(experiment: Experiment) -> Int64? {
        let variationId = keyValueRepository.getInteger(key: String(experiment.id))
        if variationId > 0 {
            return Int64(variationId)
        } else {
            return nil
        }
    }

    func set(experiment: Experiment, variationId: Int64) {
        keyValueRepository.putInteger(key: String(experiment.id), value: Int(variationId))
    }

    func remove(experiment: Experiment) {
        keyValueRepository.remove(key: String(experiment.id))
    }

    func clear() {
        keyValueRepository.clear()
    }
}
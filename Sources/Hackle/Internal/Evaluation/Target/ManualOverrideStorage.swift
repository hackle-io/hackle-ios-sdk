//
//  ManualOverrideStorage.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import Foundation


protocol ManualOverrideStorage {
    func get(experiment: Experiment, user: HackleUser) -> Variation?
}


class DelegatingManualOverrideStorage: ManualOverrideStorage {

    private let storages: [ManualOverrideStorage]

    init(storages: [ManualOverrideStorage]) {
        self.storages = storages
    }

    func get(experiment: Experiment, user: HackleUser) -> Variation? {
        for storage in storages {
            if let variation = storage.get(experiment: experiment, user: user) {
                return variation
            }
        }
        return nil
    }
}

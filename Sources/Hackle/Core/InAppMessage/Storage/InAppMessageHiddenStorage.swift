//
//  InAppMessageHiddenStorage.swift
//  Hackle
//
//  Created by yong on 2023/06/13.
//

import Foundation


protocol InAppMessageHiddenStorage {
    func exist(inAppMessage: InAppMessage, now: Date) -> Bool
    func put(inAppMessage: InAppMessage, expireAt: Date)
}


class DefaultInAppMessageHiddenStorage: InAppMessageHiddenStorage {

    private let keyValueRepository: KeyValueRepository

    init(keyValueRepository: KeyValueRepository) {
        self.keyValueRepository = keyValueRepository
    }

    static func create(suiteName: String) -> InAppMessageHiddenStorage {
        DefaultInAppMessageHiddenStorage(keyValueRepository: UserDefaultsKeyValueRepository.of(suiteName: suiteName))
    }

    func exist(inAppMessage: InAppMessage, now: Date) -> Bool {

        let key = key(inAppMessage)

        let expireTime = keyValueRepository.getDouble(key: key)
        guard expireTime > 0 else {
            return false
        }

        let expireAt = Date(timeIntervalSince1970: expireTime)
        if now <= expireAt {
            return true
        } else {
            keyValueRepository.remove(key: key)
            return false
        }
    }

    func put(inAppMessage: InAppMessage, expireAt: Date) {
        keyValueRepository.putDouble(key: key(inAppMessage), value: expireAt.timeIntervalSince1970)
    }

    private func key(_ inAppMessage: InAppMessage) -> String {
        String(inAppMessage.key)
    }
}

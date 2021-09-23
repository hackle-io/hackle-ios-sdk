//
// Created by yong on 2021/02/12.
//

import Foundation

extension UserDefaults {
    func computeIfAbsent(key: String, mapping: (String) -> String) -> String {
        guard let value = string(forKey: key) else {
            let newValue = mapping(key)
            set(newValue, forKey: key)
            synchronize()
            return newValue
        }
        return value
    }
}

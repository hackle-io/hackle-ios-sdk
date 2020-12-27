//
// Created by yong on 2020/12/11.
//

import Foundation

@objc public class Event: NSObject {

    let key: String
    let value: Double?
    let properties: [String: Any]?

    init(key: String, value: Double? = nil, properties: [String: Any]? = nil) {
        self.key = key
        self.value = value
        self.properties = properties
    }
}

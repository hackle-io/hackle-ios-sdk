//
// Created by yong on 2020/12/11.
//

import Foundation

@objc public class User: NSObject {

    let id: String
    let properties: [String: Any]?

    init(id: String, properties: [String: Any]? = nil) {
        self.id = id
        self.properties = properties
    }
}

extension User {
    typealias Id = String
}

//
// Created by yong on 2020/12/11.
//

import Foundation

@objc public class User: NSObject {

    let id: String?
    let userId: String?
    let deviceId: String?
    let identifiers: [String: String]?
    let properties: [String: Any]?

    init(id: String?, userId: String?, deviceId: String?, identifiers: [String: String]?, properties: [String: Any]?) {
        self.id = id
        self.userId = userId
        self.deviceId = deviceId
        self.identifiers = identifiers
        self.properties = properties
    }
}

extension User {
    typealias Id = String
}

//
//  IdentifierType.swift
//  Hackle
//
//  Created by yong on 2022/05/24.
//

import Foundation

enum IdentifierType: String, Codable {
    case id = "$id"
    case user = "$userId"
    case device = "$deviceId"
    case session = "$sessionId"
    case hackleDevice = "$hackleDeviceId"
}

//
//  Device.swift
//  Hackle
//
//  Created by yong on 2021/12/13.
//

import Foundation

import UIKit

class Device {

    let id: String
    let properties: [String: Any]

    init(id: String, properties: [String: Any]) {
        self.id = id
        self.properties = properties
    }
}

extension Device {

    private static let idKey = "hackle_device_id"

    static func create() -> Device {
        let deviceId = UserDefaults.standard.computeIfAbsent(key: Device.idKey) { _ in
            UUID().uuidString
        }
        let properties: [String: Any] = [
            "deviceModel": Device.model(),
            "deviceVendor": "Apple",
            "language": Locale.preferredLanguages[0],
            "osName": "iOS",
            "osVersion": UIDevice.current.systemVersion,
            "platform": "Mobile",
            "isApp": true,
            "versionName": Device.versionName()
        ]
        return Device(id: deviceId, properties: properties)
    }

    private class func model() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModelIdentifier
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        if let deviceModel = String(bytes: Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) {
            return deviceModel
        }

        return UIDevice.current.model
    }

    private class func versionName() -> String {
        if let versionName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return versionName
        } else {
            return "unknown"
        }
    }
}

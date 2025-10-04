import Foundation
import UIKit

protocol Device {
    var id: String { get }
    var properties: [String: Any] { get }
}

class DeviceImpl : Device {
    let id: String
    let platform: Platform
        
    init(id: String, platform: Platform) {
        self.id = id
        self.platform = platform
    }
    
    var properties: [String : Any] {
        get {
            let deviceInfo = platform.getCurrentDeviceInfo()
            let languageCode = deviceInfo.locale.languageCode ?? ""
            let regionCode = deviceInfo.locale.regionCode ?? ""
            return [
                "platform": "iOS",
                "osName": deviceInfo.osName,
                "osVersion": deviceInfo.osVersion,
                "deviceModel": deviceInfo.model,
                "deviceType": deviceInfo.type,
                "deviceBrand": deviceInfo.brand,
                "deviceManufacturer": deviceInfo.manufacturer,
                "locale": "\(languageCode)-\(regionCode)",
                "language": deviceInfo.locale.languageCode ?? "",
                "timeZone": deviceInfo.timezone.identifier,
                "screenWidth": deviceInfo.screenInfo.width,
                "screenHeight": deviceInfo.screenInfo.height,
                "isApp": true
            ]
        }
    }
}

extension DeviceImpl {
    static func create(keyValueRepository: KeyValueRepository) -> Device {
        let deviceId = keyValueRepository.getString(key: "hackle_device_id") { _ in
            UUID().uuidString
        }
        return DeviceImpl(
            id: deviceId,
            platform: IOSPlatform()
        )
    }
}

import Foundation
import UIKit

protocol Device {
    var id: String { get }
    var properties: [String: Any] { get }
}

class DeviceImpl : Device {
    private let deviceInfo: DeviceInfo
    let id: String

    init(deviceId: String) {
        self.id = deviceId
        self.deviceInfo = DeviceInfo(
            osName: "iOS",
            osVersion: UIDevice.current.systemVersion,
            model: DeviceHelper.getDeviceModel(),
            type: DeviceHelper.getDeviceType(),
            brand: "Apple",
            manufacturer: "Apple",
            locale: DeviceImpl.getPreferredLocale(),
            timezone: TimeZone.current,
            screenInfo: ScreenInfo(
                width: Int(UIScreen.main.nativeBounds.width),
                height: Int(UIScreen.main.nativeBounds.height)
            )
        )
        
    }
    
    var properties: [String : Any] {
        get {
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
    
    static func getDeviceId(keyValueRepository: KeyValueRepository, mapping: (String) -> String) -> String {
        return keyValueRepository.getString(key: "hackle_device_id", mapping: mapping)
    }
    
    fileprivate static func getPreferredLocale() -> Locale {
        guard let preferred = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferred)
    }
}

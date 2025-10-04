import Foundation
import UIKit

protocol Device {
    var id: String { get }
    var properties: [String: Any] { get }
}

class DeviceImpl : Device {
    let id: String
    let osName: String
    let osVersion: String
    let model: String
    let type: String
    let brand: String
    let manufacturer: String
    let locale: Locale
    let timezone: TimeZone
    let screenInfo: ScreenInfo

    init(id: String) {
        self.id = id
        self.osName = "iOS"
        self.osVersion = UIDevice.current.systemVersion
        self.model = DeviceHelper.getDeviceModel()
        self.type = DeviceHelper.getDeviceType()
        self.brand = "Apple"
        self.manufacturer = "Apple"
        self.locale = DeviceImpl.getPreferredLocale()
        self.timezone = TimeZone.current
        self.screenInfo = ScreenInfo(
            width: Int(UIScreen.main.nativeBounds.width),
            height: Int(UIScreen.main.nativeBounds.height)
        )
    }
    
    var properties: [String : Any] {
        get {
            let languageCode = locale.languageCode ?? ""
            let regionCode = locale.regionCode ?? ""
            return [
                "platform": "iOS",
                "osName": osName,
                "osVersion": osVersion,
                "deviceModel": model,
                "deviceType": type,
                "deviceBrand": brand,
                "deviceManufacturer": manufacturer,
                "locale": "\(languageCode)-\(regionCode)",
                "language": locale.languageCode ?? "",
                "timeZone": timezone.identifier,
                "screenWidth": screenInfo.width,
                "screenHeight": screenInfo.height,
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
            id: deviceId
        )
    }
    
    fileprivate static func getPreferredLocale() -> Locale {
        guard let preferred = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferred)
    }
}

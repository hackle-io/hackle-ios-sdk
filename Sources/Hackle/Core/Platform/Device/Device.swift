import Foundation
import UIKit

protocol Device {
    var id: String { get }
    var isIdCreated: Bool { get }
    var properties: [String: Any] { get }
}

class DeviceImpl : Device {
    private let osName: String
    private let osVersion: String
    private let model: String
    private let type: String
    private let brand: String
    private let manufacturer: String
    private let locale: Locale
    private let timezone: TimeZone
    private let screenInfo: ScreenInfo
    
    let id: String
    let isIdCreated: Bool

    init(id: String, isIdCreated: Bool) {
        self.id = id
        self.isIdCreated = isIdCreated
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
        var isIdCreated = false
        let deviceId = keyValueRepository.getString(key: "hackle_device_id") { _ in
            isIdCreated = true
            return UUID().uuidString
        }
        return DeviceImpl(
            id: deviceId,
            isIdCreated: isIdCreated
        )
    }
    
    fileprivate static func getPreferredLocale() -> Locale {
        guard let preferred = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferred)
    }
}

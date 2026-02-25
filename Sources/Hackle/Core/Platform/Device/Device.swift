import Foundation
import UIKit

protocol Device {
    var id: String { get }
    var properties: [String: Any] { get }
}

class DeviceImpl : Device, @unchecked Sendable {
    let id: String
    private let _deviceInfo = AtomicReference<DeviceInfo?>(value: nil)

    init(deviceId: String) {
        self.id = deviceId
    }

    @MainActor func initialize() {
        let screen = UIUtils.currentScreen
        let screenInfo = ScreenInfo(
            width: Int(screen.nativeBounds.width),
            height: Int(screen.nativeBounds.height)
        )
        let info = DeviceInfo(
            osName: "iOS",
            osVersion: UIDevice.current.systemVersion,
            model: DeviceHelper.getDeviceModel(),
            type: DeviceHelper.getDeviceType(),
            brand: "Apple",
            manufacturer: "Apple",
            locale: DeviceImpl.getPreferredLocale(),
            timezone: TimeZone.current,
            screenInfo: screenInfo
        )
        _deviceInfo.set(newValue: info)
    }

    var properties: [String : Any] {
        get {
            guard let deviceInfo = _deviceInfo.get() else {
                return ["platform": "iOS", "isApp": true]
            }
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
    fileprivate static func getPreferredLocale() -> Locale {
        guard let preferred = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferred)
    }
}

import Foundation
import UIKit

protocol Platform {
    func getCurrentDeviceInfo() -> DeviceInfo
}

class IOSPlatform : Platform {
    init() {
    }

    
    func getCurrentDeviceInfo() -> DeviceInfo {
        return DeviceInfo(
            osName: "iOS",
            osVersion: UIDevice.current.systemVersion,
            model: DeviceHelper.getDeviceModel(),
            type: DeviceHelper.getDeviceType(),
            brand: "Apple",
            manufacturer: "Apple",
            locale: getPreferredLocale(),
            timezone: TimeZone.current,
            screenInfo: DeviceInfo.ScreenInfo(
                width: Int(UIScreen.main.nativeBounds.width),
                height: Int(UIScreen.main.nativeBounds.height)
            )
        )
    }
    
    func getPreferredLocale() -> Locale {
        guard let preferred = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferred)
    }
}

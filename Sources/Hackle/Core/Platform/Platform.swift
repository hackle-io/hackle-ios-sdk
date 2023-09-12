import Foundation
import UIKit

protocol Platform {
    func getBundleInfo() -> BundleInfo
    func getCurrentDeviceInfo() -> DeviceInfo
}

class IOSPlatform : Platform {
    private let bundleInfo: BundleInfo
    
    init() {
        bundleInfo = BundleInfo(
            bundleId: Bundle.main.bundleIdentifier ?? "",
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            build: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        )
    }
    
    func getBundleInfo() -> BundleInfo {
        return bundleInfo
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
                width: Int(UIScreen.main.bounds.size.width),
                height: Int(UIScreen.main.bounds.size.height)
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

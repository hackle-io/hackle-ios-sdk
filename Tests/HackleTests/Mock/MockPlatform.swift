import Foundation
@testable import Hackle

class MockPlatform : Platform {
    func getBundleInfo() -> BundleInfo {
        return BundleInfo(
            bundleId: "io.hackle.app",
            version: "1.1.1",
            build: "10101"
        )
    }
    
    func getCurrentDeviceInfo() -> DeviceInfo {
        return DeviceInfo(
            osName: "DummyOS",
            osVersion: "1.0.0",
            model: "iPhone-hackle",
            type: "phone",
            brand: "Apple",
            manufacturer: "Foxconn",
            locale: Locale.init(identifier: "ko-KR"),
            timezone: TimeZone(identifier: "Asia/Seoul")!,
            screenInfo: DeviceInfo.ScreenInfo(
                width: 1080,
                height: 1920
            )
        )
    }
}

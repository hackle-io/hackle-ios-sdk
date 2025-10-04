import Foundation
@testable import Hackle

class MockPlatform : Platform {
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

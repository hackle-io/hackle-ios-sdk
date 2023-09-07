import Foundation
@testable import Hackle

class MockPlatform : Platform {
    var orientation: DeviceInfo.Orientation
    var connectionType: DeviceInfo.ConnectionType
    
    init(
        orientation: DeviceInfo.Orientation = .portrait,
        connectionType: DeviceInfo.ConnectionType = .wifi
    ) {
        self.orientation = orientation
        self.connectionType = connectionType
    }
    
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
                orientation: orientation,
                width: 1080,
                height: 1920
            ),
            connectionType: connectionType
        )
    }
    
    func rorateScreen() {
        if (orientation == .portrait) {
            orientation = .landscape
        } else {
            orientation = .portrait
        }
    }
    
    func changeConnectionType(connectionType: DeviceInfo.ConnectionType) {
        self.connectionType = connectionType
    }
}

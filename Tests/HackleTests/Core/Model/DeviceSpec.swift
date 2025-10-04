import Foundation
import Quick
import Nimble
@testable import Hackle

class DeviceSpec : QuickSpec {
    override func spec() {
        it("create device with static compare") {
            let deviceId = UUID().uuidString
            let platform = MockPlatform()
            let device = DeviceImpl(id: deviceId, platform: platform)
            expect(device.id) == deviceId
            expect(device.properties["platform"] as? String) == "iOS"
            expect(device.properties["osName"] as? String) == "DummyOS"
            expect(device.properties["osVersion"] as? String) == "1.0.0"
            expect(device.properties["deviceModel"] as? String) == "iPhone-hackle"
            expect(device.properties["deviceType"] as? String) == "phone"
            expect(device.properties["deviceBrand"] as? String) == "Apple"
            expect(device.properties["deviceManufacturer"] as? String) == "Foxconn"
            expect(device.properties["locale"] as? String) == "ko-KR"
            expect(device.properties["language"] as? String) == "ko"
            expect(device.properties["timeZone"] as? String) == "Asia/Seoul"
            expect(device.properties["screenWidth"] as? Int) == 1080
            expect(device.properties["screenHeight"] as? Int) == 1920
            expect(device.properties["isApp"] as? Bool) == true
        }
        
        it("create device with normal case") {
            let deviceId = UUID().uuidString
            let platform = MockPlatform()
            let device = DeviceImpl(id: deviceId, platform: platform)
            expect(device.id) == deviceId
            self.assertDeviceProperties(properties: device.properties, deviceInfo: platform.getCurrentDeviceInfo())
        }
    }
    
    func assertDeviceProperties(properties: [String: Any], deviceInfo: DeviceInfo) {
        expect(properties["platform"] as? String) == "iOS"
        expect(properties["osName"] as? String) == deviceInfo.osName
        expect(properties["osVersion"] as? String) == deviceInfo.osVersion
        expect(properties["deviceModel"] as? String) == deviceInfo.model
        expect(properties["deviceType"] as? String) == deviceInfo.type
        expect(properties["deviceBrand"] as? String) == deviceInfo.brand
        expect(properties["deviceManufacturer"] as? String) == deviceInfo.manufacturer
        expect(properties["locale"] as? String) == "\(deviceInfo.locale.languageCode!)-\(deviceInfo.locale.regionCode!)"
        expect(properties["language"] as? String) == deviceInfo.locale.languageCode
        expect(properties["timeZone"] as? String) == deviceInfo.timezone.identifier
        expect(properties["screenWidth"] as? Int) == deviceInfo.screenInfo.width
        expect(properties["screenHeight"] as? Int) == deviceInfo.screenInfo.height
        expect(properties["isApp"] as? Bool) == true
    }
}

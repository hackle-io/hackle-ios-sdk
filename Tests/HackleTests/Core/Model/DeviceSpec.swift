import Foundation
import Quick
import Nimble
@testable import Hackle

class DeviceSpec : QuickSpec {
    override func spec() {
        it("create device with required properties") {
            let deviceId = UUID().uuidString
            let device = DeviceImpl(deviceId: deviceId)
            expect(device.id) == deviceId
            expect(device.properties["platform"] as? String) == "iOS"
            expect(device.properties["osName"] as? String) == "iOS"
            expect(device.properties["osVersion"] as? String).notTo(beEmpty())
            expect(device.properties["deviceModel"] as? String).notTo(beEmpty())
            expect(device.properties["deviceType"] as? String).notTo(beEmpty())
            expect(device.properties["deviceBrand"] as? String) == "Apple"
            expect(device.properties["deviceManufacturer"] as? String) == "Apple"
            expect(device.properties["locale"] as? String).notTo(beEmpty())
            expect(device.properties["language"] as? String).notTo(beEmpty())
            expect(device.properties["timeZone"] as? String).notTo(beEmpty())
            expect(device.properties["screenWidth"] as? Int).notTo(beNil())
            expect(device.properties["screenHeight"] as? Int).notTo(beNil())
            expect(device.properties["isApp"] as? Bool) == true
        }

        it("create device with valid structure") {
            let deviceId = UUID().uuidString
            let device = DeviceImpl(deviceId: deviceId)
            expect(device.id) == deviceId
            self.assertDevicePropertiesStructure(properties: device.properties)
        }

        it("screenWidth and screenHeight should be positive values") {
            let deviceId = UUID().uuidString
            let device = DeviceImpl(deviceId: deviceId)

            let screenWidth = device.properties["screenWidth"] as? Int
            let screenHeight = device.properties["screenHeight"] as? Int

            expect(screenWidth).notTo(beNil())
            expect(screenHeight).notTo(beNil())
            expect(screenWidth).to(beGreaterThan(0))
            expect(screenHeight).to(beGreaterThan(0))
        }

        it("screen dimensions should use native bounds") {
            let deviceId = UUID().uuidString
            let device = DeviceImpl(deviceId: deviceId)

            let screenWidth = device.properties["screenWidth"] as? Int
            let screenHeight = device.properties["screenHeight"] as? Int

            // Native bounds는 보통 points bounds보다 크거나 같음 (scale factor 때문)
            expect(screenWidth).to(beGreaterThanOrEqualTo(Int(UIUtils.currentScreen.bounds.width)))
            expect(screenHeight).to(beGreaterThanOrEqualTo(Int(UIUtils.currentScreen.bounds.height)))
        }
    }

    func assertDevicePropertiesStructure(properties: [String: Any]) {
        expect(properties["platform"] as? String) == "iOS"
        expect(properties["osName"]).notTo(beNil())
        expect(properties["osVersion"]).notTo(beNil())
        expect(properties["deviceModel"]).notTo(beNil())
        expect(properties["deviceType"]).notTo(beNil())
        expect(properties["deviceBrand"]).notTo(beNil())
        expect(properties["deviceManufacturer"]).notTo(beNil())
        expect(properties["locale"]).notTo(beNil())
        expect(properties["language"]).notTo(beNil())
        expect(properties["timeZone"]).notTo(beNil())
        expect(properties["screenWidth"]).notTo(beNil())
        expect(properties["screenHeight"]).notTo(beNil())
        expect(properties["isApp"] as? Bool) == true
    }
}

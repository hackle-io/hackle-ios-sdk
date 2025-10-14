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

import Foundation
import Quick
import Nimble
@testable import Hackle

class DeviceSpec : QuickSpec {
    override class func spec() {
        it("create device with required properties") {
            let deviceId = UUID().uuidString
            let device = DeviceImpl(deviceId: deviceId)
            MainActor.assumeIsolated { device.initialize() }
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
            MainActor.assumeIsolated { device.initialize() }
            expect(device.id) == deviceId
            assertDevicePropertiesStructure(properties: device.properties)
        }

        it("screenWidth and screenHeight should be positive values") {
            let deviceId = UUID().uuidString
            let device = DeviceImpl(deviceId: deviceId)
            MainActor.assumeIsolated { device.initialize() }

            let screenWidth = device.properties["screenWidth"] as? Int
            let screenHeight = device.properties["screenHeight"] as? Int

            expect(screenWidth).notTo(beNil())
            expect(screenHeight).notTo(beNil())
            expect(screenWidth).to(beGreaterThan(0))
            expect(screenHeight).to(beGreaterThan(0))
        }

        describe("before initialize") {
            it("properties should return only platform and isApp") {
                let device = DeviceImpl(deviceId: UUID().uuidString)
                let properties = device.properties

                expect(properties.count) == 2
                expect(properties["platform"] as? String) == "iOS"
                expect(properties["isApp"] as? Bool) == true
            }

            it("properties should not contain device info") {
                let device = DeviceImpl(deviceId: UUID().uuidString)
                let properties = device.properties

                expect(properties["osName"]).to(beNil())
                expect(properties["osVersion"]).to(beNil())
                expect(properties["deviceModel"]).to(beNil())
                expect(properties["deviceType"]).to(beNil())
                expect(properties["deviceBrand"]).to(beNil())
                expect(properties["deviceManufacturer"]).to(beNil())
                expect(properties["locale"]).to(beNil())
                expect(properties["language"]).to(beNil())
                expect(properties["timeZone"]).to(beNil())
                expect(properties["screenWidth"]).to(beNil())
                expect(properties["screenHeight"]).to(beNil())
            }

            it("id should be available without initialize") {
                let deviceId = UUID().uuidString
                let device = DeviceImpl(deviceId: deviceId)
                expect(device.id) == deviceId
            }
        }

        it("initialize should populate full properties") {
            let device = DeviceImpl(deviceId: UUID().uuidString)
            expect(device.properties.count) == 2

            MainActor.assumeIsolated { device.initialize() }
            expect(device.properties.count) == 13
            assertDevicePropertiesStructure(properties: device.properties)
        }

        it("multiple initialize calls should be safe") {
            let device = DeviceImpl(deviceId: UUID().uuidString)
            MainActor.assumeIsolated {
                device.initialize()
                device.initialize()
            }
            assertDevicePropertiesStructure(properties: device.properties)
        }
    }

    static func assertDevicePropertiesStructure(properties: [String: Any]) {
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

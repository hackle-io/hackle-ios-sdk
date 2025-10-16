import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class ApplicationEventTrackerSpec: QuickSpec {
    override func spec() {
        var userManager: MockUserManager!
        var core: MockHackleCore!
        var sut: ApplicationEventTracker!

        beforeEach {
            userManager = MockUserManager()
            core = MockHackleCore()
            sut = ApplicationEventTracker(userManager: userManager, core: core)
        }

        describe("onInstall") {
            it("tracks $app_install event with version info") {
                // given
                let timestamp = Date(timeIntervalSince1970: 1000)
                let version = BundleVersionInfo(version: "2.0.0", build: 200)

                // when
                sut.onInstall(version: version, timestamp: timestamp)

                // then
                verify(exactly: 1) {
                    core.trackMock
                }

                let (event, _, trackedTimestamp) = core.trackMock.firstInvokation().arguments
                expect(event.key) == "$app_install"
                expect(event.properties?["version_name"] as? String) == "2.0.0"
                expect(event.properties?["version_code"] as? Int) == 200
                expect(trackedTimestamp) == timestamp
            }
        }

        describe("onUpdate") {
            it("tracks $app_update event with current and previous version info") {
                // given
                let timestamp = Date(timeIntervalSince1970: 2000)
                let previousVersion = BundleVersionInfo(version: "1.0.0", build: 100)
                let currentVersion = BundleVersionInfo(version: "2.0.0", build: 200)

                // when
                sut.onUpdate(previousVersion: previousVersion, currentVersion: currentVersion, timestamp: timestamp)

                // then
                verify(exactly: 1) {
                    core.trackMock
                }

                let (event, _, trackedTimestamp) = core.trackMock.firstInvokation().arguments
                expect(event.key) == "$app_update"
                expect(event.properties?["version_name"] as? String) == "2.0.0"
                expect(event.properties?["version_code"] as? Int) == 200
                expect(event.properties?["previous_version_name"] as? String) == "1.0.0"
                expect(event.properties?["previous_version_code"] as? Int) == 100
                expect(trackedTimestamp) == timestamp
            }

            it("tracks $app_update event with nil previous version when not available") {
                // given
                let timestamp = Date(timeIntervalSince1970: 2000)
                let currentVersion = BundleVersionInfo(version: "2.0.0", build: 200)

                // when
                sut.onUpdate(previousVersion: nil, currentVersion: currentVersion, timestamp: timestamp)

                // then
                let (event, _, _) = core.trackMock.firstInvokation().arguments
                expect(event.properties?["previous_version_name"]).to(beNil())
                expect(event.properties?["previous_version_code"]).to(beNil())
            }
        }

        describe("onForeground") {
            it("tracks $app_open event with isFromBackground flag") {
                // given
                let timestamp = Date(timeIntervalSince1970: 3000)

                // when
                sut.onForeground(nil, timestamp: timestamp, isFromBackground: true)

                // then
                verify(exactly: 1) {
                    core.trackMock
                }

                let (event, _, trackedTimestamp) = core.trackMock.firstInvokation().arguments
                expect(event.key) == "$app_open"
                expect(event.properties?["is_from_background"] as? Bool) == true
                expect(trackedTimestamp) == timestamp
            }

            it("tracks $app_open event with isFromBackground false") {
                // given
                let timestamp = Date(timeIntervalSince1970: 3000)

                // when
                sut.onForeground(nil, timestamp: timestamp, isFromBackground: false)

                // then
                let (event, _, _) = core.trackMock.firstInvokation().arguments
                expect(event.properties?["is_from_background"] as? Bool) == false
            }
        }

        describe("onBackground") {
            it("tracks $app_background event") {
                // given
                let timestamp = Date(timeIntervalSince1970: 4000)

                // when
                sut.onBackground(nil, timestamp: timestamp)

                // then
                verify(exactly: 1) {
                    core.trackMock
                }

                let (event, _, trackedTimestamp) = core.trackMock.firstInvokation().arguments
                expect(event.key) == "$app_background"
                expect(event.properties?.isEmpty) == true
                expect(trackedTimestamp) == timestamp
            }
        }

        describe("user resolution") {
            it("resolves user with default HackleAppContext") {
                // given
                let timestamp = Date(timeIntervalSince1970: 5000)
                let version = BundleVersionInfo(version: "2.0.0", build: 200)

                // when
                sut.onInstall(version: version, timestamp: timestamp)

                // then
                verify(exactly: 1) {
                    userManager.resolveMock
                }

                let (user, hackleAppContext) = userManager.resolveMock.firstInvokation().arguments
                expect(user).to(beNil())
                expect(hackleAppContext.browserProperties.count).to(equal(0))
            }
        }
    }
}

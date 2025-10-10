import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class ApplicationEventTrackerSpec: QuickSpec {
    override func spec() {
        var userManager: MockUserManager!
        var core: MockHackleCore!
        var bundleInfo: BundleInfo!
        var sut: ApplicationEventTracker!

        beforeEach {
            userManager = MockUserManager()
            core = MockHackleCore()
            bundleInfo = BundleInfoImpl(previousVersion: "1.0.0", previousBuild: 100)
            sut = ApplicationEventTracker(userManager: userManager, core: core, bundleInfo: bundleInfo)
        }

        describe("onInstall") {
            it("tracks $app_install event with version info") {
                // given
                let timestamp = Date(timeIntervalSince1970: 1000)

                // when
                sut.onInstall(timestamp: timestamp)

                // then
                verify(exactly: 1) {
                    core.trackMock
                }

                let (event, _, trackedTimestamp) = core.trackMock.firstInvokation().arguments
                expect(event.key) == "$app_install"
                expect(event.properties?["versionName"] as? String) == bundleInfo.currentBundleVersionInfo.version
                expect(event.properties?["versionCode"] as? Int) == bundleInfo.currentBundleVersionInfo.build
                expect(trackedTimestamp) == timestamp
            }
        }

        describe("onUpdate") {
            it("tracks $app_update event with current and previous version info") {
                // given
                let timestamp = Date(timeIntervalSince1970: 2000)

                // when
                sut.onUpdate(timestamp: timestamp)

                // then
                verify(exactly: 1) {
                    core.trackMock
                }

                let (event, _, trackedTimestamp) = core.trackMock.firstInvokation().arguments
                expect(event.key) == "$app_update"
                expect(event.properties?["versionName"] as? String) == bundleInfo.currentBundleVersionInfo.version
                expect(event.properties?["versionCode"] as? Int) == bundleInfo.currentBundleVersionInfo.build
                expect(event.properties?["previousVersionName"] as? String) == "1.0.0"
                expect(event.properties?["previousVersionCode"] as? Int) == 100
                expect(trackedTimestamp) == timestamp
            }

            it("tracks $app_update event with nil previous version when not available") {
                // given
                bundleInfo = BundleInfoImpl(previousVersion: nil, previousBuild: nil)
                sut = ApplicationEventTracker(userManager: userManager, core: core, bundleInfo: bundleInfo)
                let timestamp = Date(timeIntervalSince1970: 2000)

                // when
                sut.onUpdate(timestamp: timestamp)

                // then
                let (event, _, _) = core.trackMock.firstInvokation().arguments
                expect(event.properties?["previousVersionName"]).to(beNil())
                expect(event.properties?["previousVersionCode"]).to(beNil())
            }
        }

        describe("onForeground") {
            it("tracks $app_open event with isFromBackground flag") {
                // given
                let timestamp = Date(timeIntervalSince1970: 3000)

                // when
                sut.onForeground(timestamp: timestamp, isFromBackground: true)

                // then
                verify(exactly: 1) {
                    core.trackMock
                }

                let (event, _, trackedTimestamp) = core.trackMock.firstInvokation().arguments
                expect(event.key) == "$app_open"
                expect(event.properties?["isFromBackground"] as? Bool) == true
                expect(trackedTimestamp) == timestamp
            }

            it("tracks $app_open event with isFromBackground false") {
                // given
                let timestamp = Date(timeIntervalSince1970: 3000)

                // when
                sut.onForeground(timestamp: timestamp, isFromBackground: false)

                // then
                let (event, _, _) = core.trackMock.firstInvokation().arguments
                expect(event.properties?["isFromBackground"] as? Bool) == false
            }
        }

        describe("onBackground") {
            it("tracks $app_background event") {
                // given
                let timestamp = Date(timeIntervalSince1970: 4000)

                // when
                sut.onBackground(timestamp: timestamp)

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

                // when
                sut.onInstall(timestamp: timestamp)

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

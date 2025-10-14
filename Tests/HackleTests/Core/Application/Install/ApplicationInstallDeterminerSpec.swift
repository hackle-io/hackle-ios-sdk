import Foundation
import Quick
import Nimble
@testable import Hackle

class ApplicationInstallDeterminerSpec: QuickSpec {
    override func spec() {
        var sut: ApplicationInstallDeterminer!

        describe("determine") {
            context("when first installation") {
                beforeEach {
                    sut = ApplicationInstallDeterminer(isDeviceIdCreated: true)
                }

                it("returns install state") {
                    // given
                    let currentVersion = BundleVersionInfo(version: "2.0.0", build: 200)

                    // when
                    let state = sut.determine(previousVersion: nil, currentVersion: currentVersion)

                    // then
                    expect(state) == .install
                }
            }

            context("when device ID already exists but no previous version") {
                beforeEach {
                    sut = ApplicationInstallDeterminer(isDeviceIdCreated: false)
                }

                it("returns none state") {
                    // given
                    let currentVersion = BundleVersionInfo(version: "2.0.0", build: 200)

                    // when
                    let state = sut.determine(previousVersion: nil, currentVersion: currentVersion)

                    // then
                    expect(state) == ApplicationInstallState.none
                }
            }

            context("when app is updated") {
                beforeEach {
                    sut = ApplicationInstallDeterminer(isDeviceIdCreated: false)
                }

                it("returns update state when version differs") {
                    // given
                    let previousVersion = BundleVersionInfo(version: "1.0.0", build: 100)
                    let currentVersion = BundleVersionInfo(version: "2.0.0", build: 200)

                    // when
                    let state = sut.determine(previousVersion: previousVersion, currentVersion: currentVersion)

                    // then
                    expect(state) == .update
                }
            }

            context("when version has not changed") {
                beforeEach {
                    sut = ApplicationInstallDeterminer(isDeviceIdCreated: false)
                }

                it("returns none state") {
                    // given
                    let version = BundleVersionInfo(version: "2.0.0", build: 200)

                    // when
                    let state = sut.determine(previousVersion: version, currentVersion: version)

                    // then
                    expect(state) == ApplicationInstallState.none
                }
            }

            context("when build number changes but version stays the same") {
                beforeEach {
                    sut = ApplicationInstallDeterminer(isDeviceIdCreated: false)
                }

                it("returns update state") {
                    // given
                    let previousVersion = BundleVersionInfo(version: "2.0.0", build: 199)
                    let currentVersion = BundleVersionInfo(version: "2.0.0", build: 200)

                    // when
                    let state = sut.determine(previousVersion: previousVersion, currentVersion: currentVersion)

                    // then
                    expect(state) == .update
                }
            }
        }
    }
}

fileprivate extension String {
    func toInt() -> Int {
        Int(self) ?? 0
    }
}

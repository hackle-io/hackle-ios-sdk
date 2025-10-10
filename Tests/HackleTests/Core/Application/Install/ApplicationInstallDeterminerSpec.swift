import Foundation
import Quick
import Nimble
@testable import Hackle

class ApplicationInstallDeterminerSpec: QuickSpec {
    override func spec() {
        var repository: KeyValueRepository!
        var device: Device!
        var bundleInfo: BundleInfo!
        var sut: ApplicationInstallDeterminer!

        describe("determine") {
            context("when first installation") {
                beforeEach {
                    repository = MemoryKeyValueRepository()
                    device = MockDevice(id: "device_id", isIdCreated: true, properties: [:])
                    bundleInfo = BundleInfoImpl(previousVersion: nil, previousBuild: nil)
                    sut = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                }

                it("returns install state") {
                    // when
                    let state = sut.determine()

                    // then
                    expect(state) == .install
                }

                it("saves current version info to repository") {
                    // when
                    _ = sut.determine()

                    // then
                    let savedVersion = repository.getString(key: Bundle.KEY_PREVIOUS_VERSION)
                    let savedBuild = repository.getInteger(key: Bundle.KEY_PREVIOUS_BUILD)

                    expect(savedVersion) == bundleInfo.currentBundleVersionInfo.version
                    expect(savedBuild) == bundleInfo.currentBundleVersionInfo.build
                }
            }

            context("when device ID already exists but no previous version") {
                beforeEach {
                    repository = MemoryKeyValueRepository()
                    device = MockDevice(id: "device_id", isIdCreated: false, properties: [:])
                    bundleInfo = BundleInfoImpl(previousVersion: nil, previousBuild: nil)
                    sut = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                }

                it("returns none state") {
                    // when
                    let state = sut.determine()

                    // then
                    expect(state) == ApplicationInstallState.none
                }
            }

            context("when app is updated") {
                beforeEach {
                    repository = MemoryKeyValueRepository()
                    device = MockDevice(id: "device_id", isIdCreated: false, properties: [:])
                    bundleInfo = BundleInfoImpl(previousVersion: "1.0.0", previousBuild: 100)
                    sut = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                }

                it("returns update state when version differs") {
                    // when
                    let state = sut.determine()

                    // then
                    expect(state) == .update
                }

                it("saves new version info to repository") {
                    // when
                    _ = sut.determine()

                    // then
                    let savedVersion = repository.getString(key: Bundle.KEY_PREVIOUS_VERSION)
                    let savedBuild = repository.getInteger(key: Bundle.KEY_PREVIOUS_BUILD)

                    expect(savedVersion) == bundleInfo.currentBundleVersionInfo.version
                    expect(savedBuild) == bundleInfo.currentBundleVersionInfo.build
                }
            }

            context("when version has not changed") {
                beforeEach {
                    repository = MemoryKeyValueRepository()
                    device = MockDevice(id: "device_id", isIdCreated: false, properties: [:])

                    // Create bundleInfo with same current and previous versions
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                    let currentBuild = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "").toInt()

                    bundleInfo = BundleInfoImpl(previousVersion: currentVersion, previousBuild: currentBuild)
                    sut = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                }

                it("returns none state") {
                    // when
                    let state = sut.determine()

                    // then
                    expect(state) == ApplicationInstallState.none
                }
            }

            context("when build number changes but version stays the same") {
                beforeEach {
                    repository = MemoryKeyValueRepository()
                    device = MockDevice(id: "device_id", isIdCreated: false, properties: [:])

                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                    let currentBuild = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "").toInt()

                    bundleInfo = BundleInfoImpl(previousVersion: currentVersion, previousBuild: currentBuild - 1)
                    sut = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                }

                it("returns update state") {
                    // when
                    let state = sut.determine()

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

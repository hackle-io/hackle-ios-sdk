import Foundation
import Quick
import Nimble
@testable import Hackle

class ApplicationInstallStateManagerSpec: QuickSpec {
    override func spec() {
        var clock: Clock!
        var repository: KeyValueRepository!
        var determiner: ApplicationInstallDeterminer!
        var platformManager: PlatformManager!
        var listener: MockApplicationInstallStateListener!
        var sut: ApplicationInstallStateManager!

        beforeEach {
            clock = FixedClock(date: Date(timeIntervalSince1970: 42))
            repository = MemoryKeyValueRepository()
            listener = MockApplicationInstallStateListener()
        }

        describe("checkApplicationInstall") {
            context("when install state") {
                beforeEach {
                    determiner = ApplicationInstallDeterminer()
                    platformManager = PlatformManager(keyValueRepository: repository)
                    sut = ApplicationInstallStateManager(
                        platformManager: platformManager,
                        applicationInstallDeterminer: determiner,
                        clock: clock
                    )
                    sut.addListener(listener: listener)
                    sut.initialize()
                }

                it("notifies listeners with onInstall") {
                    // when
                    sut.checkApplicationInstall()

                    // then
                    expect(listener.installVersions.count) == 1
                    expect(listener.installTimestamps.count) == 1
                    expect(listener.installTimestamps.first) == clock.now()
                    expect(listener.updateTimestamps.count) == 0
                }

                it("notifies multiple listeners") {
                    // given
                    let listener2 = MockApplicationInstallStateListener()
                    sut.addListener(listener: listener2)

                    // when
                    sut.checkApplicationInstall()

                    // then
                    expect(listener.installTimestamps.count) == 1
                    expect(listener2.installTimestamps.count) == 1
                }
            }

            context("when update state") {
                beforeEach {
                    // Save previous version to repository
                    repository.putString(key: "hackle_previous_version", value: "1.0.0")
                    repository.putInteger(key: "hackle_previous_build", value: 100)

                    determiner = ApplicationInstallDeterminer()
                    platformManager = PlatformManager(keyValueRepository: repository)
                    sut = ApplicationInstallStateManager(
                        platformManager: platformManager,
                        applicationInstallDeterminer: determiner,
                        clock: clock
                    )
                    sut.addListener(listener: listener)
                    sut.initialize()
                }

                it("notifies listeners with onUpdate") {
                    // when
                    sut.checkApplicationInstall()

                    // then
                    expect(listener.updateTimestamps.count) == 1
                    expect(listener.updateTimestamps.first) == clock.now()
                    expect(listener.installTimestamps.count) == 0
                }
            }

            context("when none state") {
                beforeEach {
                    // Save same version as current to repository
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                    let currentBuild = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "").toInt()
                    repository.putString(key: "hackle_previous_version", value: currentVersion)
                    repository.putInteger(key: "hackle_previous_build", value: currentBuild)

                    determiner = ApplicationInstallDeterminer()
                    platformManager = PlatformManager(keyValueRepository: repository)
                    sut = ApplicationInstallStateManager(
                        platformManager: platformManager,
                        applicationInstallDeterminer: determiner,
                        clock: clock
                    )
                    sut.addListener(listener: listener)
                    sut.initialize()
                }

                it("does not notify listeners") {
                    // when
                    sut.checkApplicationInstall()

                    // then
                    expect(listener.installTimestamps.count) == 0
                    expect(listener.updateTimestamps.count) == 0
                }
            }
        }

        describe("addListener") {
            beforeEach {
                determiner = ApplicationInstallDeterminer()
                platformManager = PlatformManager(keyValueRepository: repository)
                sut = ApplicationInstallStateManager(
                    platformManager: platformManager,
                    applicationInstallDeterminer: determiner,
                    clock: clock
                )
                sut.initialize()
            }

            it("adds listener that receives notifications") {
                // given
                sut.addListener(listener: listener)

                // when
                sut.checkApplicationInstall()

                // then
                expect(listener.installTimestamps.count) == 1
            }

            it("maintains order of multiple listeners") {
                // given
                let listener1 = OrderTrackingApplicationInstallStateListener(order: 1)
                let listener2 = OrderTrackingApplicationInstallStateListener(order: 2)
                let listener3 = OrderTrackingApplicationInstallStateListener(order: 3)

                sut.addListener(listener: listener1)
                sut.addListener(listener: listener2)
                sut.addListener(listener: listener3)

                // when
                sut.checkApplicationInstall()

                // then
                expect(OrderTrackingApplicationInstallStateListener.executionOrder) == [1, 2, 3]
            }
        }
    }
}

// MARK: - Mock Listeners

class MockApplicationInstallStateListener: ApplicationInstallStateListener {
    var installVersions: [BundleVersionInfo] = []
    var installTimestamps: [Date] = []
    var updatePreviousVersions: [BundleVersionInfo?] = []
    var updateCurrentVersions: [BundleVersionInfo] = []
    var updateTimestamps: [Date] = []

    func onInstall(version: BundleVersionInfo, timestamp: Date) {
        installVersions.append(version)
        installTimestamps.append(timestamp)
    }

    func onUpdate(previousVersion: BundleVersionInfo?, currentVersion: BundleVersionInfo, timestamp: Date) {
        updatePreviousVersions.append(previousVersion)
        updateCurrentVersions.append(currentVersion)
        updateTimestamps.append(timestamp)
    }
}

class CheckingApplicationInstallStateListener: ApplicationInstallStateListener {
    private let onInstallCheck: (Date) -> Void

    init(onInstallCheck: @escaping (Date) -> Void) {
        self.onInstallCheck = onInstallCheck
    }

    func onInstall(version: BundleVersionInfo, timestamp: Date) {
        onInstallCheck(timestamp)
    }

    func onUpdate(previousVersion: BundleVersionInfo?, currentVersion: BundleVersionInfo, timestamp: Date) {
        onInstallCheck(timestamp)
    }
}

class OrderTrackingApplicationInstallStateListener: ApplicationInstallStateListener {
    static var executionOrder: [Int] = []
    let order: Int

    init(order: Int) {
        self.order = order
    }

    func onInstall(version: BundleVersionInfo, timestamp: Date) {
        OrderTrackingApplicationInstallStateListener.executionOrder.append(order)
    }

    func onUpdate(previousVersion: BundleVersionInfo?, currentVersion: BundleVersionInfo, timestamp: Date) {
        OrderTrackingApplicationInstallStateListener.executionOrder.append(order)
    }
}

fileprivate extension String {
    func toInt() -> Int {
        Int(self) ?? 0
    }
}

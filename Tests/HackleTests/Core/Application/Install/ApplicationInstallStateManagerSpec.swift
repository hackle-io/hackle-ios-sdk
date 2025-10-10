import Foundation
import Quick
import Nimble
@testable import Hackle

class ApplicationInstallStateManagerSpec: QuickSpec {
    override func spec() {
        var clock: Clock!
        var queue: DispatchQueue!
        var repository: KeyValueRepository!
        var device: Device!
        var bundleInfo: BundleInfo!
        var determiner: ApplicationInstallDeterminer!
        var listener: MockApplicationInstallStateListener!
        var sut: ApplicationInstallStateManager!

        beforeEach {
            clock = FixedClock(date: Date(timeIntervalSince1970: 42))
            queue = DispatchQueue(label: "test.queue")
            repository = MemoryKeyValueRepository()
            listener = MockApplicationInstallStateListener()
        }

        describe("checkApplicationInstall") {
            context("when install state") {
                beforeEach {
                    device = MockDevice(id: "device_id", isIdCreated: true, properties: [:])
                    bundleInfo = BundleInfoImpl(previousVersion: nil, previousBuild: nil)
                    determiner = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                    sut = ApplicationInstallStateManager(clock: clock, queue: queue, applicationInstallDeterminer: determiner)
                    sut.addListener(listener: listener)
                }

                it("notifies listeners with onInstall") {
                    // when
                    sut.checkApplicationInstall()
                    queue.sync {}
                    // then
                    waitUntil(timeout: .seconds(2)) { done in
                        if listener.installTimestamps.count > 0 {
                            expect(listener.installTimestamps.count) == 1
                            expect(listener.installTimestamps.first) == clock.now()
                            expect(listener.updateTimestamps.count) == 0
                            done()
                        }
                    }
                }

                it("notifies multiple listeners") {
                    // given
                    let listener2 = MockApplicationInstallStateListener()
                    sut.addListener(listener: listener2)

                    // when
                    sut.checkApplicationInstall()
                    queue.sync {}
                    // then
                    waitUntil(timeout: .seconds(2)) { done in
                        if listener.installTimestamps.count > 0 && listener2.installTimestamps.count > 0 {
                            expect(listener.installTimestamps.count) == 1
                            expect(listener2.installTimestamps.count) == 1
                            done()
                        }
                    }
                }
            }

            context("when update state") {
                beforeEach {
                    device = MockDevice(id: "device_id", isIdCreated: false, properties: [:])
                    bundleInfo = BundleInfoImpl(previousVersion: "1.0.0", previousBuild: 100)
                    determiner = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                    sut = ApplicationInstallStateManager(clock: clock, queue: queue, applicationInstallDeterminer: determiner)
                    sut.addListener(listener: listener)
                }

                it("notifies listeners with onUpdate") {
                    // when
                    sut.checkApplicationInstall()
                    queue.sync {}
                    // then
                    waitUntil(timeout: .seconds(2)) { done in
                        if listener.updateTimestamps.count > 0 {
                            expect(listener.updateTimestamps.count) == 1
                            expect(listener.updateTimestamps.first) == clock.now()
                            expect(listener.installTimestamps.count) == 0
                            done()
                        }
                    }
                }
            }

            context("when none state") {
                beforeEach {
                    device = MockDevice(id: "device_id", isIdCreated: false, properties: [:])
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                    let currentBuild = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "").toInt()
                    bundleInfo = BundleInfoImpl(previousVersion: currentVersion, previousBuild: currentBuild)
                    determiner = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                    sut = ApplicationInstallStateManager(clock: clock, queue: queue, applicationInstallDeterminer: determiner)
                    sut.addListener(listener: listener)
                }

                it("does not notify listeners") {
                    // when
       
                    
                    sut.checkApplicationInstall()

                    // then
                    queue.sync {}
                    queue.sync {
                        expect(listener.installTimestamps.count) == 0
                        expect(listener.updateTimestamps.count) == 0
                    }
                }
            }

            context("thread safety") {
                beforeEach {
                    device = MockDevice(id: "device_id", isIdCreated: true, properties: [:])
                    bundleInfo = BundleInfoImpl(previousVersion: nil, previousBuild: nil)
                    determiner = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                    sut = ApplicationInstallStateManager(clock: clock, queue: queue, applicationInstallDeterminer: determiner)
                }

                it("executes listener callbacks on specified queue") {
                    // given
                    let expectedQueue = queue
                    var executedOnCorrectQueue = false

                    let queueSpecificKey = DispatchSpecificKey<String>()
                    expectedQueue?.setSpecific(key: queueSpecificKey, value: "test.queue")

                    let checkingListener = CheckingApplicationInstallStateListener { timestamp in
                        let currentValue = DispatchQueue.getSpecific(key: queueSpecificKey)
                        executedOnCorrectQueue = (currentValue == "test.queue")
                    }

                    sut.addListener(listener: checkingListener)

                    // when
                    sut.checkApplicationInstall()
                    queue.sync {}
                    // then
                    waitUntil(timeout: .seconds(2)) { done in
                        if executedOnCorrectQueue {
                            expect(executedOnCorrectQueue) == true
                            done()
                        }
                    }
                }
            }
        }

        describe("addListener") {
            beforeEach {
                device = MockDevice(id: "device_id", isIdCreated: true, properties: [:])
                bundleInfo = BundleInfoImpl(previousVersion: nil, previousBuild: nil)
                determiner = ApplicationInstallDeterminer(keyValueRepository: repository, device: device, bundleInfo: bundleInfo)
                sut = ApplicationInstallStateManager(clock: clock, queue: queue, applicationInstallDeterminer: determiner)
            }

            it("adds listener that receives notifications") {
                // given
                sut.addListener(listener: listener)

                // when
                sut.checkApplicationInstall()
                queue.sync {}
                // then
                waitUntil(timeout: .seconds(2)) { done in
                    if listener.installTimestamps.count > 0 {
                        expect(listener.installTimestamps.count) == 1
                        done()
                    }
                }
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
                queue.sync {}
                // then
                waitUntil(timeout: .seconds(2)) { done in
                    if OrderTrackingApplicationInstallStateListener.executionOrder.count == 3 {
                        expect(OrderTrackingApplicationInstallStateListener.executionOrder) == [1, 2, 3]
                        done()
                    }
                }
            }
        }
    }
}

// MARK: - Mock Listeners

class MockApplicationInstallStateListener: ApplicationInstallStateListener {
    var installTimestamps: [Date] = []
    var updateTimestamps: [Date] = []

    func onInstall(timestamp: Date) {
        installTimestamps.append(timestamp)
    }

    func onUpdate(timestamp: Date) {
        updateTimestamps.append(timestamp)
    }
}

class CheckingApplicationInstallStateListener: ApplicationInstallStateListener {
    private let onInstallCheck: (Date) -> Void

    init(onInstallCheck: @escaping (Date) -> Void) {
        self.onInstallCheck = onInstallCheck
    }

    func onInstall(timestamp: Date) {
        onInstallCheck(timestamp)
    }

    func onUpdate(timestamp: Date) {
        onInstallCheck(timestamp)
    }
}

class OrderTrackingApplicationInstallStateListener: ApplicationInstallStateListener {
    static var executionOrder: [Int] = []
    let order: Int

    init(order: Int) {
        self.order = order
    }

    func onInstall(timestamp: Date) {
        OrderTrackingApplicationInstallStateListener.executionOrder.append(order)
    }

    func onUpdate(timestamp: Date) {
        OrderTrackingApplicationInstallStateListener.executionOrder.append(order)
    }
}

fileprivate extension String {
    func toInt() -> Int {
        Int(self) ?? 0
    }
}

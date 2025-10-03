import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

class LifecycleIntegrationSpecs: QuickSpec {
    override func spec() {

        var observer: ApplicationLifecycleObserver!
        var applicationManager: DefaultApplicationLifecycleManager!
        var viewManager: ViewLifecycleManager!
        var applicationListener: MockApplicationLifecycleListener!
        var viewListener: MockViewLifecycleListener!
        var queue: DispatchQueue!

        beforeEach {
            queue = DispatchQueue(label: "LifecycleIntegrationSpecs")
            observer = ApplicationLifecycleObserver()
            applicationManager = DefaultApplicationLifecycleManager.shared
            viewManager = ViewLifecycleManager(
                viewManager: MockViewManager(),
                clock: FixedClock(date: Date(timeIntervalSince1970: 42))
            )

            applicationListener = MockApplicationLifecycleListener()
            viewListener = MockViewLifecycleListener()

            applicationManager.setDispatchQueue(queue: queue)
            viewManager.setDispatchQueue(queue: queue)

            applicationManager.addListener(listener: applicationListener)
            viewManager.addListener(listener: viewListener)

            observer.addPublisher(publisher: applicationManager)
            observer.addPublisher(publisher: viewManager)
        }

        describe("Observer → Manager 통합") {
            it("Observer의 didBecomeActive가 모든 Manager에 전파됨") {
                observer.didBecomeActive()
                queue.await()

                expect(applicationManager.currentState).to(equal(.foreground))
                verify(exactly: 1) {
                    applicationListener.onForegroundMock
                }
                verify(exactly: 1) {
                    viewListener.onLifecycleMock
                }
            }

            it("Observer의 didEnterBackground가 모든 Manager에 전파됨") {
                observer.didEnterBackground()
                queue.await()

                expect(applicationManager.currentState).to(equal(.background))
                verify(exactly: 1) {
                    applicationListener.onBackgroundMock
                }
                verify(exactly: 1) {
                    viewListener.onLifecycleMock
                }
            }
        }

        describe("Lifecycle 시나리오") {
            it("앱 시작 → foreground → background → foreground") {
                observer.didBecomeActive()
                queue.await()

                verify(exactly: 1) {
                    applicationListener.onForegroundMock
                }
                let (_, isFromBackground1) = applicationListener.onForegroundMock.firstInvokation().arguments
                expect(isFromBackground1).to(beTrue())

                applicationListener.reset()
                observer.didEnterBackground()
                queue.await()

                verify(exactly: 1) {
                    applicationListener.onBackgroundMock
                }

                applicationListener.reset()
                observer.didBecomeActive()
                queue.await()

                verify(exactly: 1) {
                    applicationListener.onForegroundMock
                }
                let (_, isFromBackground2) = applicationListener.onForegroundMock.firstInvokation().arguments
                expect(isFromBackground2).to(beTrue())
            }
        }

        describe("여러 Manager 동시 동작") {
            it("Application과 View Manager가 독립적으로 동작") {
                let mockViewManager = MockViewManager()
                let vc = UIViewController()
                mockViewManager.top = vc

                let customViewManager = ViewLifecycleManager(
                    viewManager: mockViewManager,
                    clock: FixedClock(date: Date(timeIntervalSince1970: 100))
                )
                customViewManager.setDispatchQueue(queue: queue)
                customViewManager.addListener(listener: viewListener)

                observer.addPublisher(publisher: customViewManager)

                observer.didBecomeActive()
                queue.await()

                verify(exactly: 1) {
                    applicationListener.onForegroundMock
                }
                verify(atLeast: 1) {
                    viewListener.onLifecycleMock
                }
            }
        }

        describe("실행 순서") {
            it("Publisher들은 추가된 순서대로 실행") {
                let callOrder = LifecycleCallOrderTracker()

                let manager1 = TrackingApplicationLifecycleManager(tracker: callOrder, id: "app")
                let manager2 = TrackingViewLifecycleManager(tracker: callOrder, id: "view")

                let testObserver = ApplicationLifecycleObserver()
                testObserver.addPublisher(publisher: manager1)
                testObserver.addPublisher(publisher: manager2)

                testObserver.didBecomeActive()

                expect(callOrder.calls).to(equal(["app.active", "view.active"]))

                callOrder.reset()
                testObserver.didEnterBackground()

                expect(callOrder.calls).to(equal(["app.background", "view.background"]))
            }
        }
    }
}

class MockViewLifecycleListener: Mock, ViewLifecycleListener {
    lazy var onLifecycleMock = MockFunction(self, onLifecycle)

    func onLifecycle(lifecycle: ViewLifecycle, timestamp: Date) {
        call(onLifecycleMock, args: (lifecycle, timestamp))
    }
}

class LifecycleCallOrderTracker {
    var calls: [String] = []

    func record(_ call: String) {
        calls.append(call)
    }

    func reset() {
        calls.removeAll()
    }
}

class TrackingApplicationLifecycleManager: ApplicationLifecyclePublisher {
    let tracker: LifecycleCallOrderTracker
    let id: String

    init(tracker: LifecycleCallOrderTracker, id: String) {
        self.tracker = tracker
        self.id = id
    }

    func didBecomeActive() {
        tracker.record("\(id).active")
    }

    func didEnterBackground() {
        tracker.record("\(id).background")
    }
}

class TrackingViewLifecycleManager: ApplicationLifecyclePublisher {
    let tracker: LifecycleCallOrderTracker
    let id: String

    init(tracker: LifecycleCallOrderTracker, id: String) {
        self.tracker = tracker
        self.id = id
    }

    func didBecomeActive() {
        tracker.record("\(id).active")
    }

    func didEnterBackground() {
        tracker.record("\(id).background")
    }
}

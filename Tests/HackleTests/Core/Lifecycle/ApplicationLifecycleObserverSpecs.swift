import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

class ApplicationLifecycleObserverSpecs: QuickSpec {
    override func spec() {

        var sut: ApplicationLifecycleObserver!
        var publisher1: MockApplicationLifecyclePublisher!
        var publisher2: MockApplicationLifecyclePublisher!

        beforeEach {
            sut = ApplicationLifecycleObserver()
            publisher1 = MockApplicationLifecyclePublisher()
            publisher2 = MockApplicationLifecyclePublisher()
        }

        describe("초기화") {
            it("initialize()는 한 번만 실행되어야 함") {
                sut.initialize()
                sut.initialize()
                sut.initialize()
            }
        }

        describe("publisher 관리") {
            it("여러 publisher를 추가할 수 있음") {
                sut.addPublisher(publisher: publisher1)
                sut.addPublisher(publisher: publisher2)

                sut.didBecomeActive()

                verify(exactly: 1) {
                    publisher1.didBecomeActiveMock
                }
                verify(exactly: 1) {
                    publisher2.didBecomeActiveMock
                }
            }
        }

        describe("didBecomeActive") {
            it("모든 publisher에게 didBecomeActive를 전달") {
                sut.addPublisher(publisher: publisher1)
                sut.addPublisher(publisher: publisher2)

                sut.didBecomeActive()

                verify(exactly: 1) {
                    publisher1.didBecomeActiveMock
                }
                verify(exactly: 1) {
                    publisher2.didBecomeActiveMock
                }
            }
        }

        describe("didEnterBackground") {
            it("모든 publisher에게 didEnterBackground를 전달") {
                sut.addPublisher(publisher: publisher1)
                sut.addPublisher(publisher: publisher2)

                sut.didEnterBackground()

                verify(exactly: 1) {
                    publisher1.didEnterBackgroundMock
                }
                verify(exactly: 1) {
                    publisher2.didEnterBackgroundMock
                }
            }
        }

        describe("순서 보장") {
            it("publisher들은 추가된 순서대로 통지받음") {
                let callOrder = CallOrderTracker()

                let publisher1 = CallOrderPublisher(order: callOrder, id: "1")
                let publisher2 = CallOrderPublisher(order: callOrder, id: "2")
                let publisher3 = CallOrderPublisher(order: callOrder, id: "3")

                sut.addPublisher(publisher: publisher1)
                sut.addPublisher(publisher: publisher2)
                sut.addPublisher(publisher: publisher3)

                sut.didBecomeActive()

                expect(callOrder.calls).to(equal(["1", "2", "3"]))
            }
        }
    }
}

class MockApplicationLifecyclePublisher: Mock, ApplicationLifecyclePublisher {
    lazy var didBecomeActiveMock = MockFunction(self, didBecomeActive)
    lazy var didEnterBackgroundMock = MockFunction(self, didEnterBackground)

    func didBecomeActive() {
        call(didBecomeActiveMock, args: ())
    }

    func didEnterBackground() {
        call(didEnterBackgroundMock, args: ())
    }
}

class CallOrderTracker {
    var calls: [String] = []

    func record(_ id: String) {
        calls.append(id)
    }
}

class CallOrderPublisher: ApplicationLifecyclePublisher {
    let order: CallOrderTracker
    let id: String

    init(order: CallOrderTracker, id: String) {
        self.order = order
        self.id = id
    }

    func didBecomeActive() {
        order.record(id)
    }

    func didEnterBackground() {
        order.record(id)
    }
}

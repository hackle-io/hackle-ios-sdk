import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

class DefaultApplicationLifecycleManagerSpecs: QuickSpec {
    override func spec() {
        var queue: DispatchQueue!
        var listener: MockApplicationLifecycleListener!

        beforeEach {
            queue = DispatchQueue(label: "DefaultApplicationLifecycleManagerSpecs")
            listener = MockApplicationLifecycleListener()
        }

        describe("lifecycle events") {
            it("didBecomeActive") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)
                sut.addListener(listener: listener)

                sut.didBecomeActive()
                queue.await()
                expect(sut.currentState == .foreground).to(beTrue())
                verify(exactly: 1) {
                    listener.onForegroundMock
                }
            }
            it("didEnterBackground") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)
                sut.addListener(listener: listener)

                sut.didEnterBackground()
                queue.await()
                expect(sut.currentState == .background).to(beTrue())
                verify(exactly: 1) {
                    listener.onBackgroundMock
                }
            }
        }

        describe("상태 추적") {
            it("초기 상태는 background") {
                let sut = DefaultApplicationLifecycleManager.shared
                expect(sut.currentState).to(equal(Optional(.background)))
            }

            it("didBecomeActive 호출 후 상태는 foreground") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)

                sut.didBecomeActive()
                queue.await()

                expect(sut.currentState).to(equal(.foreground))
            }

            it("didEnterBackground 호출 후 상태는 background") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)

                sut.didBecomeActive()
                queue.await()
                sut.didEnterBackground()
                queue.await()

                expect(sut.currentState).to(equal(Optional(.background)))
            }
        }

        describe("isFromBackground 파라미터") {
            it("background에서 foreground로 전환 시 isFromBackground는 true") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)
                sut.addListener(listener: listener)

                sut.didEnterBackground()
                queue.await()

                sut.didBecomeActive()
                queue.await()

                verify(exactly: 1) {
                    listener.onForegroundMock
                }
                let (_, isFromBackground) = listener.onForegroundMock.firstInvokation().arguments
                expect(isFromBackground).to(beTrue())
            }

            it("초기 상태에서 foreground로 전환 시 isFromBackground는 false") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)
                sut.addListener(listener: listener)

                sut.didBecomeActive()
                queue.await()

                verify(exactly: 1) {
                    listener.onForegroundMock
                }
                let (_, isFromBackground) = listener.onForegroundMock.firstInvokation().arguments
                expect(isFromBackground).to(beFalse())
            }

            it("foreground -> background -> foreground로 전환 시 isFromBackground는 true") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)
                sut.addListener(listener: listener)

                sut.didBecomeActive()
                queue.await()
                
                sut.didEnterBackground()
                queue.await()

                sut.didBecomeActive()
                queue.await()

                verify(exactly: 2) {
                    listener.onForegroundMock
                }
                let (_, isFromBackground) = listener.onForegroundMock.lastInvokation().arguments
                expect(isFromBackground).to(beTrue())
            }
        }

        describe("여러 listener") {
            it("모든 listener가 통지받음") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)

                let listener1 = MockApplicationLifecycleListener()
                let listener2 = MockApplicationLifecycleListener()
                let listener3 = MockApplicationLifecycleListener()

                sut.addListener(listener: listener1)
                sut.addListener(listener: listener2)
                sut.addListener(listener: listener3)

                sut.didBecomeActive()
                queue.await()

                verify(exactly: 1) { listener1.onForegroundMock }
                verify(exactly: 1) { listener2.onForegroundMock }
                verify(exactly: 1) { listener3.onForegroundMock }

                sut.didEnterBackground()
                queue.await()

                verify(exactly: 1) { listener1.onBackgroundMock }
                verify(exactly: 1) { listener2.onBackgroundMock }
                verify(exactly: 1) { listener3.onBackgroundMock }
            }
        }
    }
}


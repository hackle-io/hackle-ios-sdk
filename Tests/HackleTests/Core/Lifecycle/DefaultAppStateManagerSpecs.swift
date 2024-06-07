import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

class DefaultAppStateManagerSpecs: QuickSpec {
    override func spec() {
        var queue: DispatchQueue!
        var listener: MockAppStateListener!
        var sut: DefaultAppStateManager!

        beforeEach {
            queue = DispatchQueue(label: "DefaultAppStateManagerSpecs")
            listener = MockAppStateListener()
            sut = DefaultAppStateManager(queue: queue)
            sut.addListener(listener: listener)
        }

        describe("onLifecycle") {
            it("didBecomeActive") {
                sut.onLifecycle(lifecycle: .didBecomeActive(top: nil), timestamp: Date(timeIntervalSince1970: 42))
                queue.await()
                expect(sut.currentState).to(equal(.foreground))
                verify(exactly: 1) {
                    listener.onStateMock
                }
                expect(listener.onStateMock.firstInvokation().arguments.0).to(equal(.foreground))
            }
            it("didEnterBackground") {
                sut.onLifecycle(lifecycle: .didEnterBackground(top: nil), timestamp: Date(timeIntervalSince1970: 42))
                queue.await()
                expect(sut.currentState).to(equal(.background))
                verify(exactly: 1) {
                    listener.onStateMock
                }
                expect(listener.onStateMock.firstInvokation().arguments.0).to(equal(.background))
            }

            it("do nothing") {
                sut.onLifecycle(lifecycle: .viewWillAppear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                sut.onLifecycle(lifecycle: .viewDidAppear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                sut.onLifecycle(lifecycle: .viewWillDisappear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                sut.onLifecycle(lifecycle: .viewDidDisappear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                queue.await()
                expect(sut.currentState).to(equal(.background))
                verify(exactly: 0) {
                    listener.onStateMock
                }
            }
        }
    }
}

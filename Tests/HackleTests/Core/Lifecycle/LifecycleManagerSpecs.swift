import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

class LifecycleManagerSpecs: QuickSpec {
    override func spec() {

        var viewManager: MockViewManager!
        var listener: MockLifecycleListener!
        var sut: ViewLifecycleManager!

        beforeEach {
            viewManager = MockViewManager()
            listener = MockLifecycleListener()
            sut = ViewLifecycleManager(viewManager: viewManager, clock: FixedClock(date: Date(timeIntervalSince1970: 42)))
            sut.addListener(listener: listener)
        }

        it("willEnterForeground") {
            let vc = UIViewController()
            viewManager.top = vc
            sut.willEnterForeground()

            verify(exactly: 1) {
                listener.onLifecycleMock
            }
            let (lifecycle, _) = listener.onLifecycleMock.firstInvokation().arguments
            if case let .willEnterForeground(top) = lifecycle {
                expect(top).to(beIdenticalTo(vc))
            } else {
                fail("willEnterForeground")
            }
        }

        it("didEnterBackground") {
            let vc = UIViewController()
            viewManager.top = vc
            sut.didEnterBackground()

            verify(exactly: 1) {
                listener.onLifecycleMock
            }
            let (lifecycle, timestamp) = listener.onLifecycleMock.firstInvokation().arguments
            if case let .didEnterBackground(top) = lifecycle {
                expect(top).to(beIdenticalTo(vc))
            } else {
                fail("didEnterBackground")
            }
            expect(timestamp).to(equal(Date(timeIntervalSince1970: 42)))
        }

        it("viewWillAppear") {
            let vc = UIViewController()
            let top = UIViewController()

            sut.viewWillAppear(vc: vc)
            verify(exactly: 0) {
                listener.onLifecycleMock
            }

            viewManager.top = top
            sut.viewWillAppear(vc: vc)
            verify(exactly: 1) {
                listener.onLifecycleMock
            }
            let (lifecycle, timestamp) = listener.onLifecycleMock.firstInvokation().arguments
            if case let .viewWillAppear(v, t) = lifecycle {
                expect(v).to(beIdenticalTo(vc))
                expect(t).to(beIdenticalTo(top))
            } else {
                fail("viewWillAppear")
            }
            expect(timestamp).to(equal(Date(timeIntervalSince1970: 42)))
        }

        it("viewDidAppear") {
            let vc = UIViewController()
            let top = UIViewController()

            sut.viewDidAppear(vc: vc)
            verify(exactly: 0) {
                listener.onLifecycleMock
            }

            viewManager.top = top
            sut.viewDidAppear(vc: vc)
            verify(exactly: 1) {
                listener.onLifecycleMock
            }
            let (lifecycle, timestamp) = listener.onLifecycleMock.firstInvokation().arguments
            if case let .viewDidAppear(v, t) = lifecycle {
                expect(v).to(beIdenticalTo(vc))
                expect(t).to(beIdenticalTo(top))
            } else {
                fail("viewDidAppear")
            }
            expect(timestamp).to(equal(Date(timeIntervalSince1970: 42)))
        }

        it("viewWillDisappear") {
            let vc = UIViewController()
            let top = UIViewController()

            sut.viewWillDisappear(vc: vc)
            verify(exactly: 0) {
                listener.onLifecycleMock
            }

            viewManager.top = top
            sut.viewWillDisappear(vc: vc)
            verify(exactly: 1) {
                listener.onLifecycleMock
            }
            let (lifecycle, timestamp) = listener.onLifecycleMock.firstInvokation().arguments
            if case let .viewWillDisappear(v, t) = lifecycle {
                expect(v).to(beIdenticalTo(vc))
                expect(t).to(beIdenticalTo(top))
            } else {
                fail("viewWillDisappear")
            }
            expect(timestamp).to(equal(Date(timeIntervalSince1970: 42)))
        }

        it("viewDidDisappear") {
            let vc = UIViewController()
            let top = UIViewController()

            sut.viewDidDisappear(vc: vc)
            verify(exactly: 0) {
                listener.onLifecycleMock
            }

            viewManager.top = top
            sut.viewDidDisappear(vc: vc)
            verify(exactly: 1) {
                listener.onLifecycleMock
            }
            let (lifecycle, timestamp) = listener.onLifecycleMock.firstInvokation().arguments
            if case let .viewDidDisappear(v, t) = lifecycle {
                expect(v).to(beIdenticalTo(vc))
                expect(t).to(beIdenticalTo(top))
            } else {
                fail("viewDidDisappear")
            }
            expect(timestamp).to(equal(Date(timeIntervalSince1970: 42)))
        }
    }
}

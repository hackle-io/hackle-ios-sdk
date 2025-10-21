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

        describe("viewWillAppear") {
            context("when top is nil") {
                it("should not call listener") {
                    let vc = UIViewController()
                    viewManager.top = nil
                    viewManager.isOwnedView = true

                    sut.viewWillAppear(vc: vc)

                    verify(exactly: 0) {
                        listener.onLifecycleMock
                    }
                }
            }

            context("when isOwnedView is false") {
                it("should not call listener") {
                    let vc = UIViewController()
                    let top = UIViewController()
                    viewManager.top = top
                    viewManager.isOwnedView = false

                    sut.viewWillAppear(vc: vc)

                    verify(exactly: 0) {
                        listener.onLifecycleMock
                    }
                }
            }

            context("when top is valid and isOwnedView is true") {
                it("should call listener with correct parameters") {
                    let vc = UIViewController()
                    let top = UIViewController()
                    viewManager.top = top
                    viewManager.isOwnedView = true

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
            }
        }

        describe("viewDidAppear") {
            context("when top is nil") {
                it("should not call listener") {
                    let vc = UIViewController()
                    viewManager.top = nil
                    viewManager.isOwnedView = true

                    sut.viewDidAppear(vc: vc)

                    verify(exactly: 0) {
                        listener.onLifecycleMock
                    }
                }
            }

            context("when isOwnedView is false") {
                it("should not call listener") {
                    let vc = UIViewController()
                    let top = UIViewController()
                    viewManager.top = top
                    viewManager.isOwnedView = false

                    sut.viewDidAppear(vc: vc)

                    verify(exactly: 0) {
                        listener.onLifecycleMock
                    }
                }
            }

            context("when top is valid and isOwnedView is true") {
                it("should call listener with correct parameters") {
                    let vc = UIViewController()
                    let top = UIViewController()
                    viewManager.top = top
                    viewManager.isOwnedView = true

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
            }
        }

        describe("viewWillDisappear") {
            context("when top is nil") {
                it("should not call listener") {
                    let vc = UIViewController()
                    viewManager.top = nil
                    viewManager.isOwnedView = true

                    sut.viewWillDisappear(vc: vc)

                    verify(exactly: 0) {
                        listener.onLifecycleMock
                    }
                }
            }

            context("when isOwnedView is false") {
                it("should not call listener") {
                    let vc = UIViewController()
                    let top = UIViewController()
                    viewManager.top = top
                    viewManager.isOwnedView = false

                    sut.viewWillDisappear(vc: vc)

                    verify(exactly: 0) {
                        listener.onLifecycleMock
                    }
                }
            }

            context("when top is valid and isOwnedView is true") {
                it("should call listener with correct parameters") {
                    let vc = UIViewController()
                    let top = UIViewController()
                    viewManager.top = top
                    viewManager.isOwnedView = true

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
            }
        }

        describe("viewDidDisappear") {
            context("when top is nil") {
                it("should not call listener") {
                    let vc = UIViewController()
                    viewManager.top = nil
                    viewManager.isOwnedView = true

                    sut.viewDidDisappear(vc: vc)

                    verify(exactly: 0) {
                        listener.onLifecycleMock
                    }
                }
            }

            context("when isOwnedView is false") {
                it("should not call listener") {
                    let vc = UIViewController()
                    let top = UIViewController()
                    viewManager.top = top
                    viewManager.isOwnedView = false

                    sut.viewDidDisappear(vc: vc)

                    verify(exactly: 0) {
                        listener.onLifecycleMock
                    }
                }
            }

            context("when top is valid and isOwnedView is true") {
                it("should call listener with correct parameters") {
                    let vc = UIViewController()
                    let top = UIViewController()
                    viewManager.top = top
                    viewManager.isOwnedView = true

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
    }
}

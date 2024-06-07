import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

class DefaultScreenManagerSpecs: QuickSpec {
    override func spec() {
        var userManager: MockUserManager!
        var listener: MockScreenListener!
        var sut: DefaultScreenManager!

        beforeEach {
            userManager = MockUserManager()
            listener = MockScreenListener()
            sut = DefaultScreenManager(userManager: userManager)
            sut.addListener(listener: listener)
        }

        describe("updateScreen") {
            it("when first screen then start screen") {
                // given
                let screen = Screen(name: "name", className: "class")

                // when
                sut.updateScreen(screen: screen, timestamp: Date(timeIntervalSince1970: 42))

                // then
                expect(sut.currentScreen).to(equal(screen))
                verify(exactly: 0) {
                    listener.onScreenEndedMock
                }
                verify(exactly: 1) {
                    listener.onScreenStartedMock
                }
            }

            it("when current screen and new screen are same then do nothing") {
                // given
                let screen = Screen(name: "name", className: "class")
                sut.updateScreen(screen: screen, timestamp: Date(timeIntervalSince1970: 42))

                // when
                sut.updateScreen(screen: screen, timestamp: Date(timeIntervalSince1970: 43))

                // then
                expect(sut.currentScreen).to(equal(screen))
                verify(exactly: 0) {
                    listener.onScreenEndedMock
                }
                verify(exactly: 1) {
                    listener.onScreenStartedMock
                }
                let (previousScreen, currentScreen, user, timestamp) = listener.onScreenStartedMock.firstInvokation().arguments
                expect(previousScreen).to(beNil())
                expect(currentScreen).to(equal(screen))
                expect(timestamp).to(equal(Date(timeIntervalSince1970: 42)))
            }

            it("when current screen and new screen are different then start new screen") {
                // given
                let screen = Screen(name: "name", className: "class")
                sut.updateScreen(screen: screen, timestamp: Date(timeIntervalSince1970: 42))
                let newScreen = Screen(name: "new_name", className: "new_class")

                // when
                sut.updateScreen(screen: newScreen, timestamp: Date(timeIntervalSince1970: 43))

                // then
                expect(sut.currentScreen).to(equal(newScreen))
                verify(exactly: 1) {
                    listener.onScreenEndedMock
                }
                let (endScreen, _, endTs) = listener.onScreenEndedMock.firstInvokation().arguments
                expect(endScreen).to(equal(screen))
                expect(endTs).to(equal(Date(timeIntervalSince1970: 43)))
                verify(exactly: 2) {
                    listener.onScreenStartedMock
                }
                let (previousScreen, currentScreen, _, timestamp) = listener.onScreenStartedMock.invokations()[0].arguments
                expect(previousScreen).to(beNil())
                expect(currentScreen).to(equal(screen))
                expect(timestamp).to(equal(Date(timeIntervalSince1970: 42)))

                let (previousScreen2, currentScreen2, _, timestamp2) = listener.onScreenStartedMock.invokations()[1].arguments
                expect(previousScreen2).to(equal(screen))
                expect(currentScreen2).to(equal(newScreen))
                expect(timestamp2).to(equal(Date(timeIntervalSince1970: 43)))
            }
        }

        describe("onLifecycle") {
            context("didBecomeActive") {
                it("when top view is nil then do nothing") {
                    // when
                    sut.onLifecycle(lifecycle: .didBecomeActive(top: nil), timestamp: Date())

                    // then
                    expect(sut.currentScreen).to(beNil())
                }

                it("when top view is present then update screen") {
                    // when
                    sut.onLifecycle(lifecycle: .didBecomeActive(top: TestViewController()), timestamp: Date())

                    // then
                    expect(sut.currentScreen).to(equal(Screen(name: "TestViewController", className: "TestViewController")))
                }
            }

            context("viewDidAppear") {
                it("update screen with top view") {
                    sut.onLifecycle(lifecycle: .viewDidAppear(vc: TestViewController(), top: TopViewController()), timestamp: Date())
                    expect(sut.currentScreen).to(equal(Screen(name: "TopViewController", className: "TopViewController")))
                }
            }

            context("viewDidDisappear") {
                it("update screen with top view") {
                    sut.onLifecycle(lifecycle: .viewDidDisappear(vc: TestViewController(), top: TopViewController()), timestamp: Date())
                    expect(sut.currentScreen).to(equal(Screen(name: "TopViewController", className: "TopViewController")))
                }
            }

            it("do nothing") {
                sut.onLifecycle(lifecycle: .viewWillAppear(vc: TestViewController(), top: TopViewController()), timestamp: Date())
                sut.onLifecycle(lifecycle: .viewWillDisappear(vc: TestViewController(), top: TopViewController()), timestamp: Date())
                sut.onLifecycle(lifecycle: .didEnterBackground(top: TopViewController()), timestamp: Date())
                expect(sut.currentScreen).to(beNil())
            }
        }
    }

    private class TestViewController: UIViewController {

    }

    private class TopViewController: UIViewController {

    }
}
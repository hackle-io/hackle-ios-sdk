import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

class EngagementManagerSpecs: QuickSpec {
    override func spec() {
        let user = User.builder().build()
        var userManager: MockUserManager!
        var screenManager: MockScreeManager!
        var listener: MockEngagementListener!
        var sut: EngagementManager!

        beforeEach {
            userManager = MockUserManager()
            screenManager = MockScreeManager()
            sut = EngagementManager(userManager: userManager, screenManager: screenManager, minimumEngagementDuration: 1.0)
            listener = MockEngagementListener()
            sut.addListener(listener: listener)
        }

        describe("onScreenStarted") {
            it("start engagement") {
                sut.onScreenStarted(previousScreen: nil, currentScreen: Screen(name: "name", className: "class"), user: User.builder().build(), timestamp: Date(timeIntervalSince1970: 42))
                expect(sut.lastEngagementTime).to(equal(Date(timeIntervalSince1970: 42)))
            }
        }

        describe("onScreenEnded") {
            it("when last engagement time is nil then do nothing") {
                // given
                let screen = Screen(name: "name", className: "class")

                // when
                sut.onScreenEnded(screen: screen, user: User.builder().build(), timestamp: Date(timeIntervalSince1970: 42))

                // then
                verify(exactly: 0) {
                    listener.onEngagementMock
                }
            }

            it("when engagement time is less than min time then do nothing") {
                // given
                let screen = Screen(name: "name", className: "class")
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 42.0))

                // when
                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 42.999))

                // then
                verify(exactly: 0) {
                    listener.onEngagementMock
                }
            }

            it("track engagement event") {
                // given
                let screen = Screen(name: "name", className: "class")
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 42.0))

                // when
                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 43))

                // then
                verify(exactly: 1) {
                    listener.onEngagementMock
                }
                let (engagement, _, timestamp) = listener.onEngagementMock.firstInvokation().arguments
                expect(engagement).to(equal(Engagement(screen: screen, duration: 1.0)))
                expect(timestamp).to(equal(Date(timeIntervalSince1970: 43)))
            }
        }

        describe("onLifecycle") {
            context("viewDidAppear") {
                it("start engagement") {
                    sut.onLifecycle(lifecycle: .viewDidAppear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                    expect(sut.lastEngagementTime).to(equal(Date(timeIntervalSince1970: 42)))
                }
            }
            context("didBecomeActive") {
                it("start engagement") {
                    sut.onLifecycle(lifecycle: .didBecomeActive(top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                    expect(sut.lastEngagementTime).to(equal(Date(timeIntervalSince1970: 42)))
                }
            }
            context("viewDidDisappear") {
                it("when current screen is nil then do nothing") {
                    sut.onLifecycle(lifecycle: .viewDidDisappear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                    verify(exactly: 0) {
                        listener.onEngagementMock
                    }
                }

                it("end engagement") {
                    // given
                    let screen = Screen(name: "name", className: "class")
                    screenManager.currentScreen = screen
                    sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 42))

                    // when
                    sut.onLifecycle(lifecycle: .viewDidDisappear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 43))

                    // then
                    verify(exactly: 1) {
                        listener.onEngagementMock
                    }
                    let (engagement, _, timestamp) = listener.onEngagementMock.firstInvokation().arguments
                    expect(engagement).to(equal(Engagement(screen: screen, duration: 1.0)))
                    expect(timestamp).to(equal(Date(timeIntervalSince1970: 43)))
                }
            }
            context("didEnterBackground") {
                it("when current screen is nil then do nothing") {
                    sut.onLifecycle(lifecycle: .didEnterBackground(top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                    verify(exactly: 0) {
                        listener.onEngagementMock
                    }
                }

                it("end engagement") {
                    // given
                    let screen = Screen(name: "name", className: "class")
                    screenManager.currentScreen = screen
                    sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 42))

                    // when
                    sut.onLifecycle(lifecycle: .didEnterBackground(top: UIViewController()), timestamp: Date(timeIntervalSince1970: 43))

                    // then
                    verify(exactly: 1) {
                        listener.onEngagementMock
                    }
                    let (engagement, _, timestamp) = listener.onEngagementMock.firstInvokation().arguments
                    expect(engagement).to(equal(Engagement(screen: screen, duration: 1.0)))
                    expect(timestamp).to(equal(Date(timeIntervalSince1970: 43)))
                }
            }
            it("do nothing") {
                let screen = Screen(name: "name", className: "class")
                screenManager.currentScreen = screen
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 42))

                sut.onLifecycle(lifecycle: .viewWillAppear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 43))
                sut.onLifecycle(lifecycle: .viewWillDisappear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 43))

                verify(exactly: 0) {
                    listener.onEngagementMock
                }
            }
        }
    }
}

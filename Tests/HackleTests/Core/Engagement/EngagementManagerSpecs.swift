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
            it("do nothing for all view lifecycle events") {
                let screen = Screen(name: "name", className: "class")
                screenManager.currentScreen = screen
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 42))

                sut.onLifecycle(lifecycle: .viewDidAppear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                sut.onLifecycle(lifecycle: .viewDidDisappear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 42))
                sut.onLifecycle(lifecycle: .viewWillAppear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 43))
                sut.onLifecycle(lifecycle: .viewWillDisappear(vc: UIViewController(), top: UIViewController()), timestamp: Date(timeIntervalSince1970: 43))

                verify(exactly: 0) {
                    listener.onEngagementMock
                }
            }
        }

        describe("call engagement") {
            it("multiple start without end - only last start is considered") {
                // given
                let screen = Screen(name: "name", className: "class")

                // when - multiple start engagements
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 100))
                sut.onScreenStarted(previousScreen: screen, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 200))
                sut.onScreenStarted(previousScreen: screen, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 300))
                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 500))

                // then - engagement duration calculated from last start (300ms)
                verify(exactly: 1) {
                    listener.onEngagementMock
                }
                let (engagement, _, timestamp) = listener.onEngagementMock.firstInvokation().arguments
                expect(engagement.duration).to(equal(200.0))
                expect(timestamp).to(equal(Date(timeIntervalSince1970: 500)))
            }

            it("multiple end without start - no engagement published") {
                // given
                let screen = Screen(name: "name", className: "class")

                // when - multiple end engagements without start
                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 100))
                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 200))
                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 300))

                // then - no engagement published
                verify(exactly: 0) {
                    listener.onEngagementMock
                }
            }

            it("start-end-end sequence - second end does nothing") {
                // given
                let screen = Screen(name: "name", className: "class")

                // when
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 100))
                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 300)) // first end - should publish
                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 400)) // second end - should do nothing

                // then - only one engagement published
                verify(exactly: 1) {
                    listener.onEngagementMock
                }
                let (engagement, _, timestamp) = listener.onEngagementMock.firstInvokation().arguments
                expect(engagement.duration).to(equal(200.0))
                expect(timestamp).to(equal(Date(timeIntervalSince1970: 300)))
            }

            it("start-end-start-end sequence - two engagements published") {
                // given
                let screen1 = Screen(name: "screen1", className: "class1")
                let screen2 = Screen(name: "screen2", className: "class2")

                // when
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen1, user: user, timestamp: Date(timeIntervalSince1970: 100))
                sut.onScreenEnded(screen: screen1, user: user, timestamp: Date(timeIntervalSince1970: 300)) // first engagement
                sut.onScreenStarted(previousScreen: screen1, currentScreen: screen2, user: user, timestamp: Date(timeIntervalSince1970: 400))
                sut.onScreenEnded(screen: screen2, user: user, timestamp: Date(timeIntervalSince1970: 600)) // second engagement

                // then - two engagements published
                verify(exactly: 2) {
                    listener.onEngagementMock
                }
            }
        }

        describe("state management") {
            it("lastEngagementTime cleared after endEngagement") {
                // given
                let screen = Screen(name: "name", className: "class")

                // when
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 100))
                expect(sut.lastEngagementTime).to(equal(Date(timeIntervalSince1970: 100)))

                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 300))

                // then
                expect(sut.lastEngagementTime).to(beNil())
            }

            it("lastEngagementTime cleared after endEngagement even if not published") {
                // given
                let screen = Screen(name: "name", className: "class")

                // when - engagement too short to be published
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: user, timestamp: Date(timeIntervalSince1970: 100))
                sut.onScreenEnded(screen: screen, user: user, timestamp: Date(timeIntervalSince1970: 100.1))

                // then - lastEngagementTime should still be cleared
                expect(sut.lastEngagementTime).to(beNil())
                verify(exactly: 0) {
                    listener.onEngagementMock
                }
            }
        }
    }
}

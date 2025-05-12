import Foundation
import Quick
import Nimble
@testable import Hackle

class ScreenEventTrackerSpecs: QuickSpec {
    override func spec() {
        var userManager: MockUserManager!
        var core: MockHackleCore!
        var sut: ScreenEventTracker!

        beforeEach {
            userManager = MockUserManager()
            core = MockHackleCore()
            sut = ScreenEventTracker(userManager: userManager, core: core)
        }

        it("event metadata") {
            expect(ScreenEventTracker.SCREEN_VIEW_EVENT_KEY).to(equal("$page_view"))
            expect(ScreenEventTracker.SCREEN_NAME_PROPERTY_KEY).to(equal("$page_name"))
            expect(ScreenEventTracker.SCREEN_CLASS_PROPERTY_KEY).to(equal("$page_class"))
        }

        describe("onScreenStarted") {
            it("previousScreen = nil") {
                // given
                let screen = Screen(name: "name", className: "class")
                every(userManager.toHackleUserMock).returns(HackleUser.builder().build())

                // when
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: User.builder().build(), timestamp: Date())

                // then
                verify(exactly: 1) {
                    core.trackMock
                }
                let event = core.trackMock.firstInvokation().arguments.0
                expect(event.properties!["$page_name"] as? String).to(equal("name"))
                expect(event.properties!["$page_class"] as? String).to(equal("class"))
                expect(event.properties!["$previous_page_name"]).to(beNil())
                expect(event.properties!["$previous_page_class"]).to(beNil())
            }

            it("previousScreen != nil") {
                // given
                let previousScreen = Screen(name: "prev_name", className: "prev_class")
                let screen = Screen(name: "name", className: "class")
                every(userManager.toHackleUserMock).returns(HackleUser.builder().build())

                // when
                sut.onScreenStarted(previousScreen: previousScreen, currentScreen: screen, user: User.builder().build(), timestamp: Date())

                // then
                verify(exactly: 1) {
                    core.trackMock
                }
                let event = core.trackMock.firstInvokation().arguments.0
                expect(event.properties!["$page_name"] as? String).to(equal("name"))
                expect(event.properties!["$page_class"] as? String).to(equal("class"))
                expect(event.properties!["$previous_page_name"] as? String).to(equal("prev_name"))
                expect(event.properties!["$previous_page_class"] as? String).to(equal("prev_class"))
            }
        }

        describe("onScreenStarted") {
            it("do nothing") {
                sut.onScreenEnded(screen: Screen(name: "name", className: "class"), user: User.builder().build(), timestamp: Date())
            }
        }
    }
}

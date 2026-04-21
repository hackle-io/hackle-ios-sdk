import Foundation
import Quick
import Nimble
@testable import Hackle

class ScreenEventTrackerSpecs: QuickSpec {
    override class func spec() {
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
            expect(ScreenEventTracker.PREVIOUS_SCREEN_NAME_PROPERTY_KEY).to(equal("$previous_page_name"))
            expect(ScreenEventTracker.PREVIOUS_SCREEN_CLASS_PROPERTY_KEY).to(equal("$previous_page_class"))
        }

        describe("onScreenStarted") {
            it("previousScreen = nil") {
                // given
                let screen = Screen.builder(name: "name", className: "class").build()
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
                let previousScreen = Screen.builder(name: "prev_name", className: "prev_class").build()
                let screen = Screen.builder(name: "name", className: "class").build()
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

            it("includes custom screen properties in $page_view event") {
                // given
                let screen = Screen.builder(name: "Home", className: "HomeVC")
                    .property("user_segment", "premium")
                    .property("entry_point", "push_notification")
                    .property("campaign_id", 12345)
                    .build()
                every(userManager.toHackleUserMock).returns(HackleUser.builder().build())

                // when
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: User.builder().build(), timestamp: Date())

                // then
                verify(exactly: 1) {
                    core.trackMock
                }
                let event = core.trackMock.firstInvokation().arguments.0
                expect(event.key).to(equal("$page_view"))
                expect(event.properties!["$page_name"] as? String).to(equal("Home"))
                expect(event.properties!["$page_class"] as? String).to(equal("HomeVC"))
                expect(event.properties!["user_segment"] as? String).to(equal("premium"))
                expect(event.properties!["entry_point"] as? String).to(equal("push_notification"))
                expect(event.properties!["campaign_id"] as? Int).to(equal(12345))
            }

            it("includes empty properties when screen has no custom properties") {
                // given
                let screen = Screen.builder(name: "EmptyProps", className: "EmptyPropsVC").build()
                every(userManager.toHackleUserMock).returns(HackleUser.builder().build())

                // when
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: User.builder().build(), timestamp: Date())

                // then
                verify(exactly: 1) {
                    core.trackMock
                }
                let event = core.trackMock.firstInvokation().arguments.0
                expect(event.properties!["$page_name"] as? String).to(equal("EmptyProps"))
                expect(event.properties!["$page_class"] as? String).to(equal("EmptyPropsVC"))
                // Custom properties should not be present
                expect(event.properties!.keys.filter { !$0.hasPrefix("$") }.count).to(equal(0))
            }

            it("merges screen properties with default properties") {
                // given
                let screen = Screen.builder(name: "Product", className: "ProductVC")
                    .property("product_id", "ABC-123")
                    .property("category", "electronics")
                    .build()
                every(userManager.toHackleUserMock).returns(HackleUser.builder().build())

                // when
                sut.onScreenStarted(previousScreen: nil, currentScreen: screen, user: User.builder().build(), timestamp: Date())

                // then
                verify(exactly: 1) {
                    core.trackMock
                }
                let event = core.trackMock.firstInvokation().arguments.0
                // Default properties should be preserved
                expect(event.properties!["$page_name"] as? String).to(equal("Product"))
                expect(event.properties!["$page_class"] as? String).to(equal("ProductVC"))
                // Custom properties should be added
                expect(event.properties!["product_id"] as? String).to(equal("ABC-123"))
                expect(event.properties!["category"] as? String).to(equal("electronics"))
            }

            it("includes screen properties with previous screen information") {
                // given
                let previousScreen = Screen.builder(name: "PrevScreen", className: "PrevVC").build()
                let currentScreen = Screen.builder(name: "CurrentScreen", className: "CurrentVC")
                    .property("session_id", "session-123")
                    .property("user_action", "button_click")
                    .build()
                every(userManager.toHackleUserMock).returns(HackleUser.builder().build())

                // when
                sut.onScreenStarted(previousScreen: previousScreen, currentScreen: currentScreen, user: User.builder().build(), timestamp: Date())

                // then
                verify(exactly: 1) {
                    core.trackMock
                }
                let event = core.trackMock.firstInvokation().arguments.0
                // All properties should be present
                expect(event.properties!["$page_name"] as? String).to(equal("CurrentScreen"))
                expect(event.properties!["$page_class"] as? String).to(equal("CurrentVC"))
                expect(event.properties!["$previous_page_name"] as? String).to(equal("PrevScreen"))
                expect(event.properties!["$previous_page_class"] as? String).to(equal("PrevVC"))
                expect(event.properties!["session_id"] as? String).to(equal("session-123"))
                expect(event.properties!["user_action"] as? String).to(equal("button_click"))
            }
            
            it("screen properties contain page_name and page_class then they are overridden by screen name and className") {
                // given
                let currentScreen = Screen.builder(name: "correct_screen_name", className: "correct_screen_class")
                    .property("$page_name", "wrong_name")
                    .property("$page_class", "wrong_class")
                    .property("$previous_page_name", "wrong_prev_name")
                    .property("$previous_page_class", "wrong_prev_class")
                    .property("custom_key", "custom_value")
                    .build()
                let prevScreen = Screen.builder(name: "correct_prev_name", className: "correct_prev_class")
                    .build()
                
                every(userManager.toHackleUserMock).returns(HackleUser.builder().build())
                
                // when
                sut.onScreenStarted(previousScreen: prevScreen, currentScreen: currentScreen, user: User.builder().build(), timestamp: Date())
                // then
                verify(exactly: 1) {
                    core.trackMock
                }
                
                let event = core.trackMock.firstInvokation().arguments.0
                expect(event.properties!["$page_name"] as? String).to(equal("correct_screen_name"))
                expect(event.properties!["$page_class"] as? String).to(equal("correct_screen_class"))
                expect(event.properties!["$previous_page_name"] as? String).to(equal("correct_prev_name"))
                expect(event.properties!["$previous_page_class"] as? String).to(equal("correct_prev_class"))
                expect(event.properties!["custom_key"] as? String).to(equal("custom_value"))
            }
        }
    }
}

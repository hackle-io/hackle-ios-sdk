import Foundation
import WebKit
import Quick
import Nimble
import MockingKit
@testable import Hackle

class InAppMessageUIHtmlViewSpecs: QuickSpec {
    override class func spec() {
        typealias HtmlView = HackleInAppMessageUI.HtmlView
        typealias BridgeScript = HackleInAppMessageUI.HtmlViewBridgeScript

        let sdkKey = "test_sdk_key"

        @MainActor
        func makeView(scheduler: Scheduler) -> HtmlView {
            let app = HackleApp(
                hackleAppCore: MockHackleAppCore(sdkKey: sdkKey),
                sdk: Sdk.of(sdkKey: sdkKey, config: HackleConfig.DEFAULT),
                config: HackleConfig.DEFAULT,
                hackleInvocator: DefaultHackleInvocator(processor: MockInvocationProcessor()),
                urlDispatcher: HackleUrlDispatcher(defaultHandler: ApplicationUrlHandler())
            )
            return HtmlView(
                context: InAppMessageEntity.context(),
                app: app,
                contentResolverFactory: DefaultInAppMessageHtmlContentResolverFactory(
                    resolvers: [TextInAppMessageHtmlContentResolver()]
                ),
                bridgeScript: BridgeScript.create(config: HackleConfig.DEFAULT),
                scheduler: scheduler
            )
        }

        it("keeps web data out of the persistent store shared with the host app's web views") {
            MainActor.assumeIsolated {
                let view = makeView(scheduler: MockScheduler())

                expect(view.webView.configuration.websiteDataStore.isPersistent) == false
            }
        }

        it("isolates cookies in both directions from the host app web view") {
            MainActor.assumeIsolated {
                let view = makeView(scheduler: MockScheduler())
                let hostStore = WKWebsiteDataStore.default().httpCookieStore
                let messageStore = view.webView.configuration.websiteDataStore.httpCookieStore
                let name = "iam_isolation_" + UUID().uuidString
                let hostCookie = HTTPCookie(properties: [
                    .domain: "iam-isolation.example", .path: "/",
                    .name: name, .value: "host"
                ])!
                let messageCookie = HTTPCookie(properties: [
                    .domain: "iam-isolation.example", .path: "/",
                    .name: name, .value: "message"
                ])!

                waitUntil(timeout: .seconds(10)) { done in
                    hostStore.setCookie(hostCookie) {
                        hostStore.getAllCookies { hostCookies in
                            expect(hostCookies.first { $0.name == name }?.value) == "host"
                            messageStore.getAllCookies { messageCookies in
                                expect(messageCookies.contains { $0.name == name }).to(beFalse())
                                messageStore.setCookie(messageCookie) {
                                    messageStore.getAllCookies { updatedMessageCookies in
                                        expect(updatedMessageCookies.first { $0.name == name }?.value) == "message"
                                        hostStore.getAllCookies { unchangedHostCookies in
                                            expect(unchangedHostCookies.first { $0.name == name }?.value) == "host"
                                            hostStore.delete(hostCookie) {
                                                messageStore.delete(messageCookie) { done() }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        it("schedules a load timeout with the configured 30s delay") {
            MainActor.assumeIsolated {
                let scheduler = MockScheduler()
                every(scheduler.scheduleMock).returns(MockScheduledJob())
                let view = makeView(scheduler: scheduler)

                view.scheduleLoadTimeout()

                verify(exactly: 1) { scheduler.scheduleMock }
                let (delay, _) = scheduler.scheduleMock.firstInvokation().arguments
                expect(delay) == HtmlView.loadTimeout
                expect(HtmlView.loadTimeout) == 30
            }
        }

        it("dismisses the view when load times out before ready") {
            MainActor.assumeIsolated {
                let view = makeView(scheduler: MockScheduler())

                view.onLoadTimeout()

                expect(view.isDismissed).to(beTrue())
                expect(view.presented).to(beFalse())
            }
        }

        it("does not dismiss on timeout if already presented") {
            MainActor.assumeIsolated {
                let view = makeView(scheduler: MockScheduler())
                view.presented = true

                view.onLoadTimeout()

                expect(view.isDismissed).to(beFalse())
            }
        }

        it("does not present content after dismiss (no false impression)") {
            MainActor.assumeIsolated {
                let view = makeView(scheduler: MockScheduler())

                view.dismiss()
                view.showContent()

                expect(view.presented).to(beFalse())
            }
        }

        it("cancels the load timeout on dismiss and is idempotent") {
            MainActor.assumeIsolated {
                let scheduler = MockScheduler()
                let job = MockScheduledJob()
                every(scheduler.scheduleMock).returns(job)
                let view = makeView(scheduler: scheduler)
                view.scheduleLoadTimeout()

                view.dismiss()
                view.dismiss()

                verify(exactly: 1) { job.cancelMock }
                expect(view.isDismissed).to(beTrue())
            }
        }
    }
}

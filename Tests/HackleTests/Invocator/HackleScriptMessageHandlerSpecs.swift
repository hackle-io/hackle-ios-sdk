import Foundation
import Nimble
import Quick
import WebKit
@testable import Hackle

class HackleScriptMessageHandlerSpecs: QuickSpec {
    override class func spec() {

        let mutationBody = "{\"_hackle\":{\"command\":\"setUser\",\"parameters\":{}},\"requestId\":\"req-1\"}"
        let trackBody = "{\"_hackle\":{\"command\":\"track\",\"parameters\":{\"event\":\"purchase\"}}}"

        var invocator: MockInvocator!
        var webView: MockWebView!

        beforeEach {
            invocator = MockInvocator()
            MainActor.assumeIsolated {
                webView = MockWebView()
            }
        }

        describe("userContentController(_:didReceive:)") {

            it("메인 프레임이 아닌 메시지는 무시한다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)
                    let message = MockScriptMessage(body: mutationBody, frameInfo: MockFrameInfo.subFrame, webView: webView)

                    sut.userContentController(WKUserContentController(), didReceive: message)

                    expect(invocator.invokedStrings).to(beEmpty())
                }
            }

            it("문자열이 아닌 body는 무시한다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)
                    let message = MockScriptMessage(body: ["_hackle": ["command": "setUser"]], webView: webView)

                    sut.userContentController(WKUserContentController(), didReceive: message)

                    expect(invocator.invokedStrings).to(beEmpty())
                }
            }

            it("메인 프레임의 문자열 메시지는 invocator에 위임한다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)
                    let message = MockScriptMessage(body: trackBody, webView: webView)

                    sut.userContentController(WKUserContentController(), didReceive: message)

                    expect(invocator.invokedStrings) == [trackBody]
                }
            }
        }

        describe("handle(body:webView:)") {

            it("invocable하지 않은 문자열은 무시한다") {
                MainActor.assumeIsolated {
                    invocator.invocable = false
                    let sut = HackleScriptMessageHandler(invocator: invocator)

                    sut.handle(body: "{\"foo\":\"bar\"}", webView: webView)

                    expect(invocator.invokedStrings).to(beEmpty())
                    expect(webView.evaluatedScripts).to(beEmpty())
                }
            }

            it("requestId가 없으면 invoke만 하고 resolve하지 않는다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)

                    sut.handle(body: trackBody, webView: webView)

                    expect(invocator.invokedStrings) == [trackBody]
                    expect(invocator.asyncInvokedStrings).to(beEmpty())
                    expect(webView.evaluatedScripts).to(beEmpty())
                }
            }

            it("requestId가 있으면 completion 시점에 resolve를 발송한다") {
                MainActor.assumeIsolated {
                    invocator.invokeResult = "{\"success\":true,\"message\":\"OK\"}"
                    let sut = HackleScriptMessageHandler(invocator: invocator)

                    sut.handle(body: mutationBody, webView: webView)

                    expect(invocator.asyncInvokedStrings) == [mutationBody]
                    expect(webView.evaluatedScripts.count) == 1
                    expect(webView.evaluatedScripts.first)
                        == "window._hackleBridge && window._hackleBridge.resolve(\"req-1\", \"{\\\"success\\\":true,\\\"message\\\":\\\"OK\\\"}\")"
                }
            }

            it("웹뷰가 해제되었으면 resolve를 발송하지 않는다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)

                    sut.handle(body: mutationBody, webView: nil)

                    expect(invocator.asyncInvokedStrings) == [mutationBody]
                }
            }

            it("message 채널 사용 카운터를 증가시킨다") {
                MainActor.assumeIsolated {
                    Metrics.clear()
                    let registry = CumulativeMetricRegistry()
                    Metrics.addRegistry(registry: registry)
                    let sut = HackleScriptMessageHandler(invocator: invocator)

                    sut.handle(body: trackBody, webView: webView)

                    expect(registry.counter(name: "webview.bridge.message").count()) == 1
                }
            }
        }

        describe("resolveScript") {

            it("requestId와 response를 이스케이프해 담는다") {
                expect(HackleScriptMessageHandler.resolveScript(requestId: "req-1", response: "{\"success\":true}"))
                    == "window._hackleBridge && window._hackleBridge.resolve(\"req-1\", \"{\\\"success\\\":true}\")"
            }
        }

        describe("WeakScriptMessageHandler") {

            it("핸들러를 강하게 참조하지 않는다") {
                MainActor.assumeIsolated {
                    var handler: HackleScriptMessageHandler? = HackleScriptMessageHandler(invocator: invocator)
                    weak var weakHandler = handler
                    let proxy = WeakScriptMessageHandler(handler!)

                    handler = nil

                    expect(weakHandler).to(beNil())
                    _ = proxy
                }
            }

            it("핸들러가 살아있으면 메시지를 전달한다") {
                MainActor.assumeIsolated {
                    let handler = HackleScriptMessageHandler(invocator: invocator)
                    let proxy = WeakScriptMessageHandler(handler)
                    let message = MockScriptMessage(body: trackBody, webView: webView)

                    proxy.userContentController(WKUserContentController(), didReceive: message)

                    expect(invocator.invokedStrings) == [trackBody]
                }
            }
        }
    }
}

// MARK: - Test Doubles

private class MockInvocator: NSObject, HackleInvocator {
    var invocable = true
    var invokeResult = "{\"success\":true,\"message\":\"OK\"}"
    var invokedStrings: [String] = []
    var asyncInvokedStrings: [String] = []

    func isInvocableString(string: String) -> Bool {
        invocable
    }

    func invoke(string: String) -> String {
        invokedStrings.append(string)
        return invokeResult
    }

    func invoke(string: String, completionHandler: (String?) -> Void) {
        invokedStrings.append(string)
        completionHandler(invokeResult)
    }

    func invokeAsync(string: String, completionHandler: @escaping (String?) -> Void) {
        invokedStrings.append(string)
        asyncInvokedStrings.append(string)
        completionHandler(invokeResult)
    }
}

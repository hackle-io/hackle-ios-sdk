import Foundation
import Nimble
import Quick
import WebKit
@testable import Hackle

class HackleScriptMessageHandlerSpecs: QuickSpec {
    override class func spec() {

        let mutationBody = "{\"_hackle\":{\"command\":\"setUser\",\"parameters\":{},\"messageId\":\"req-1\"}}"
        let trackBody = "{\"_hackle\":{\"command\":\"track\",\"parameters\":{\"event\":\"purchase\"}}}"
        let trackBodyWithMessageId = "{\"_hackle\":{\"command\":\"track\",\"parameters\":{\"event\":\"purchase\"},\"messageId\":\"req-2\"}}"

        var invocator: MockInvocator!
        var webView: MockWebView!

        beforeEach {
            invocator = MockInvocator()
            MainActor.assumeIsolated {
                webView = MockWebView()
            }
        }

        describe("didReceive(_:)") {

            it("메인 프레임이 아닌 메시지도 처리한다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)
                    let message = MockScriptMessage(body: trackBodyWithMessageId, frameInfo: MockFrameInfo.subFrame, webView: webView)

                    sut.didReceive(message)

                    expect(invocator.invokedStrings) == [trackBodyWithMessageId]
                }
            }

            it("문자열이 아닌 body는 무시한다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)
                    let message = MockScriptMessage(body: ["_hackle": ["command": "setUser"]], webView: webView)

                    sut.didReceive(message)

                    expect(invocator.invokedStrings).to(beEmpty())
                }
            }

            it("메인 프레임의 문자열 메시지는 invocator에 위임한다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)
                    let message = MockScriptMessage(body: trackBodyWithMessageId, webView: webView)

                    sut.didReceive(message)

                    expect(invocator.invokedStrings) == [trackBodyWithMessageId]
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

            it("messageId가 없으면 처리하지 않는다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)

                    sut.handle(body: trackBody, webView: webView)

                    expect(invocator.invokedStrings).to(beEmpty())
                    expect(invocator.asyncInvokedStrings).to(beEmpty())
                    expect(webView.evaluatedScripts).to(beEmpty())
                }
            }

            it("messageId가 있으면 completion 시점에 resolve를 발송한다") {
                MainActor.assumeIsolated {
                    invocator.invokeResult = "{\"success\":true,\"message\":\"OK\"}"
                    let sut = HackleScriptMessageHandler(invocator: invocator)

                    sut.handle(body: mutationBody, webView: webView)

                    expect(invocator.asyncInvokedStrings) == [mutationBody]
                    expect(webView.evaluatedScripts.count) == 1
                    expect(webView.evaluatedScripts.first)
                        == "window._hackleBridge && window._hackleBridge.resolveMessage(\"req-1\", \"{\\\"success\\\":true,\\\"message\\\":\\\"OK\\\"}\")"
                }
            }

            it("웹뷰가 해제되었으면 resolve를 발송하지 않는다") {
                MainActor.assumeIsolated {
                    let sut = HackleScriptMessageHandler(invocator: invocator)

                    sut.handle(body: mutationBody, webView: nil)

                    expect(invocator.asyncInvokedStrings) == [mutationBody]
                }
            }
        }

        describe("resolveScript") {

            it("messageId와 response를 이스케이프해 담는다") {
                expect(HackleScriptMessageHandler.resolveScript(messageId: "req-1", response: "{\"success\":true}"))
                    == "window._hackleBridge && window._hackleBridge.resolveMessage(\"req-1\", \"{\\\"success\\\":true}\")"
            }
        }

        describe("HackleScriptMessageDispatcher") {

            it("message.webView의 handler로만 전달한다") {
                MainActor.assumeIsolated {
                    let firstInvocator = MockInvocator()
                    let secondInvocator = MockInvocator()
                    let firstWebView = MockWebView()
                    let secondWebView = MockWebView()
                    firstWebView._messageHandler = HackleScriptMessageHandler(invocator: firstInvocator)
                    secondWebView._messageHandler = HackleScriptMessageHandler(invocator: secondInvocator)
                    let sut = HackleScriptMessageDispatcher()

                    sut.userContentController(
                        WKUserContentController(),
                        didReceive: MockScriptMessage(body: trackBodyWithMessageId, webView: firstWebView)
                    )

                    expect(firstInvocator.invokedStrings) == [trackBodyWithMessageId]
                    expect(secondInvocator.invokedStrings).to(beEmpty())
                }
            }

            it("handler가 없는 WebView의 메시지는 무시한다") {
                MainActor.assumeIsolated {
                    let handlerWebView = MockWebView()
                    handlerWebView._messageHandler = HackleScriptMessageHandler(invocator: invocator)
                    let sut = HackleScriptMessageDispatcher()

                    sut.userContentController(
                        WKUserContentController(),
                        didReceive: MockScriptMessage(body: trackBodyWithMessageId, webView: webView)
                    )

                    expect(invocator.invokedStrings).to(beEmpty())
                }
            }
        }
    }
}

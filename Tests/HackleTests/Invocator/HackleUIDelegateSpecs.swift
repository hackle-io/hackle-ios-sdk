import Foundation
import Quick
import Nimble
import WebKit
@testable import Hackle

class HackleUIDelegateSpecs: QuickSpec {
    override func spec() {

        var mockInvocator: MockInvocator!

        beforeEach {
            mockInvocator = MockInvocator()
        }

        describe("webView runJavaScriptTextInputPanelWithPrompt") {

            it("invocable prompt should invoke and return result via completionHandler") {
                MainActor.assumeIsolated {
                    let sut = HackleUIDelegate(invocator: mockInvocator)
                    mockInvocator.invocable = true
                    mockInvocator.invokeResult = "{\"result\":\"ok\"}"

                    let webView = WKWebView()
                    let frame = WKFrameInfo()
                    var callbackResult: String? = "not_called"

                    sut.webView(
                        webView,
                        runJavaScriptTextInputPanelWithPrompt: "test_prompt",
                        defaultText: nil,
                        initiatedByFrame: frame
                    ) { result in
                        callbackResult = result
                    }

                    expect(mockInvocator.invokedString) == "test_prompt"
                    expect(callbackResult) == "{\"result\":\"ok\"}"
                }
            }

            it("non-invocable prompt without uiDelegate should call completionHandler with nil") {
                MainActor.assumeIsolated {
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: nil)
                    mockInvocator.invocable = false

                    let webView = WKWebView()
                    let frame = WKFrameInfo()
                    var callbackResult: String? = "not_called"

                    sut.webView(
                        webView,
                        runJavaScriptTextInputPanelWithPrompt: "non_hackle_prompt",
                        defaultText: nil,
                        initiatedByFrame: frame
                    ) { result in
                        callbackResult = result
                    }

                    expect(callbackResult).to(beNil())
                }
            }

            it("non-invocable prompt with uiDelegate should forward to uiDelegate") {
                MainActor.assumeIsolated {
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    mockInvocator.invocable = false

                    let webView = WKWebView()
                    let frame = WKFrameInfo()
                    var callbackResult: String? = "not_called"

                    sut.webView(
                        webView,
                        runJavaScriptTextInputPanelWithPrompt: "external_prompt",
                        defaultText: "default",
                        initiatedByFrame: frame
                    ) { result in
                        callbackResult = result
                    }

                    expect(mockUIDelegate.promptCalled) == true
                    expect(mockUIDelegate.receivedPrompt) == "external_prompt"
                    expect(mockUIDelegate.receivedDefaultText) == "default"
                    expect(callbackResult) == "delegated_result"
                }
            }

            it("non-invocable prompt with uiDelegate that does not implement prompt method should call completionHandler with nil") {
                MainActor.assumeIsolated {
                    let minimalDelegate = MinimalWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: minimalDelegate)
                    mockInvocator.invocable = false

                    let webView = WKWebView()
                    let frame = WKFrameInfo()
                    var callbackResult: String? = "not_called"

                    sut.webView(
                        webView,
                        runJavaScriptTextInputPanelWithPrompt: "some_prompt",
                        defaultText: nil,
                        initiatedByFrame: frame
                    ) { result in
                        callbackResult = result
                    }

                    expect(callbackResult).to(beNil())
                }
            }
        }

        describe("responds(to:)") {

            it("should return true for selectors HackleUIDelegate responds to") {
                MainActor.assumeIsolated {
                    let sut = HackleUIDelegate(invocator: mockInvocator)
                    let selector = #selector(WKUIDelegate.webView(_:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:))
                    expect(sut.responds(to: selector)) == true
                }
            }

            it("should forward responds(to:) to uiDelegate for unknown selectors") {
                MainActor.assumeIsolated {
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    let selector = #selector(MockWKUIDelegate.customMethod)
                    expect(sut.responds(to: selector)) == true
                }
            }

            it("should return false when no uiDelegate and selector is unknown") {
                MainActor.assumeIsolated {
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: nil)
                    let selector = #selector(MockWKUIDelegate.customMethod)
                    expect(sut.responds(to: selector)) == false
                }
            }
        }

        describe("forwardingTarget(for:)") {

            it("should return self for selectors HackleUIDelegate handles") {
                MainActor.assumeIsolated {
                    let sut = HackleUIDelegate(invocator: mockInvocator)
                    let selector = #selector(WKUIDelegate.webView(_:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:))
                    let target = sut.forwardingTarget(for: selector)
                    expect(target).to(beIdenticalTo(sut))
                }
            }

            it("should return uiDelegate for selectors HackleUIDelegate does not handle") {
                MainActor.assumeIsolated {
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    let selector = #selector(MockWKUIDelegate.customMethod)
                    let target = sut.forwardingTarget(for: selector)
                    expect(target).to(beIdenticalTo(mockUIDelegate))
                }
            }

            it("should return nil when no uiDelegate and selector is unknown") {
                MainActor.assumeIsolated {
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: nil)
                    let selector = #selector(MockWKUIDelegate.customMethod)
                    let target = sut.forwardingTarget(for: selector)
                    expect(target).to(beNil())
                }
            }
        }
    }
}

// MARK: - Test Doubles

private class MockInvocator: NSObject, HackleInvocator {
    var invocable = false
    var invokeResult = ""
    var invokedString: String?

    func isInvocableString(string: String) -> Bool {
        invocable
    }

    func invoke(string: String) -> String {
        invokedString = string
        return invokeResult
    }

    func invoke(string: String, completionHandler: (String?) -> Void) {
        invokedString = string
        completionHandler(invokeResult)
    }
}

private class MockWKUIDelegate: NSObject, WKUIDelegate {
    var promptCalled = false
    var receivedPrompt: String?
    var receivedDefaultText: String?

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor @Sendable (String?) -> Void) {
        promptCalled = true
        receivedPrompt = prompt
        receivedDefaultText = defaultText
        completionHandler("delegated_result")
    }

    @objc func customMethod() {}
}

private class MinimalWKUIDelegate: NSObject, WKUIDelegate {
}

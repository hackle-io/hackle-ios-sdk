import Foundation
import Quick
import Nimble
import WebKit
@testable import Hackle

class HackleUIDelegateSpecs: QuickSpec {
    override class func spec() {

        var mockInvocator: MockInvocator!

        beforeEach {
            mockInvocator = MockInvocator()
        }

        describe("runJavaScriptTextInputPanelWithPrompt") {

            it("invocable prompt는 동기로 invoke 결과를 반환한다") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    mockInvocator.invocable = true
                    mockInvocator.invokeResult = "{\"success\":true,\"data\":\"A\"}"
                    let sut = HackleUIDelegate(invocator: mockInvocator)
                    let json = "{\"_hackle\":{\"command\":\"variation\",\"parameters\":{\"experimentKey\":42}}}"

                    let result = AtomicReference<String?>(value: nil)
                    sut.webView(
                        webView,
                        runJavaScriptTextInputPanelWithPrompt: json,
                        defaultText: nil,
                        initiatedByFrame: MockFrameInfo.mainFrame
                    ) { result.set(newValue: $0) }

                    expect(mockInvocator.invokedStrings) == [json]
                    expect(result.get()) == "{\"success\":true,\"data\":\"A\"}"
                }
            }

            it("invocable하지 않은 prompt는 위임 delegate가 없으면 nil을 반환한다") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    mockInvocator.invocable = false
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: nil)

                    let called = AtomicReference(value: false)
                    let result = AtomicReference<String?>(value: nil)
                    sut.webView(
                        webView,
                        runJavaScriptTextInputPanelWithPrompt: "hello",
                        defaultText: nil,
                        initiatedByFrame: MockFrameInfo.mainFrame
                    ) {
                        called.set(newValue: true)
                        result.set(newValue: $0)
                    }

                    expect(called.get()) == true
                    expect(result.get()).to(beNil())
                    expect(mockInvocator.invokedStrings).to(beEmpty())
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

            it("should keep responding to every selector used by PayApp after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    var mockUIDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    mockUIDelegate = nil

                    let selectors = [
                        #selector(WKUIDelegate.webView(_:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)),
                        #selector(WKUIDelegate.webView(_:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)),
                        #selector(WKUIDelegate.webView(_:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)),
                        #selector(WKUIDelegate.webView(_:createWebViewWith:for:windowFeatures:)),
                        #selector(WKUIDelegate.webViewDidClose(_:)),
                    ]

                    for selector in selectors {
                        expect(sut.responds(to: selector)) == true
                    }
                }
            }
        }

        describe("weak uiDelegate reference") {

            it("should not retain uiDelegate") {
                MainActor.assumeIsolated {
                    var mockDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    weak var weakRef = mockDelegate

                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockDelegate)
                    _ = sut
                    mockDelegate = nil

                    expect(weakRef).to(beNil())
                }
            }

            it("responds(to:) should return false after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    var mockDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockDelegate)
                    mockDelegate = nil

                    let selector = #selector(MockWKUIDelegate.customMethod)
                    expect(sut.responds(to: selector)) == false
                }
            }

            it("forwardingTarget(for:) should return nil after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    var mockDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockDelegate)
                    mockDelegate = nil

                    let selector = #selector(MockWKUIDelegate.customMethod)
                    let target = sut.forwardingTarget(for: selector)
                    expect(target).to(beNil())
                }
            }
        }

        describe("forwardingTarget(for:)") {

            it("should return self for selectors HackleUIDelegate handles") {
                MainActor.assumeIsolated {
                    let sut = HackleUIDelegate(invocator: mockInvocator)
                    let selector = #selector(WKUIDelegate.webView(_:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:))
                    let target = sut.forwardingTarget(for: selector)
                    expect(target as? HackleUIDelegate).to(beIdenticalTo(sut))
                }
            }

            it("should return uiDelegate for selectors HackleUIDelegate does not handle") {
                MainActor.assumeIsolated {
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    let selector = #selector(MockWKUIDelegate.customMethod)
                    let target = sut.forwardingTarget(for: selector)
                    expect(target as? MockWKUIDelegate).to(beIdenticalTo(mockUIDelegate))
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

        describe("webViewDidClose(_:)") {

            it("should forward to uiDelegate while it is alive") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    let selector = #selector(WKUIDelegate.webViewDidClose(_:))

                    _ = sut.perform(selector, with: webView)

                    expect(mockUIDelegate.webViewDidCloseCallCount) == 1
                    expect(mockUIDelegate.receivedClosedWebView).to(beIdenticalTo(webView))
                }
            }

            it("should be a safe no-op when the cached selector arrives after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    var mockUIDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    let selector = #selector(WKUIDelegate.webViewDidClose(_:))
                    mockUIDelegate = nil

                    expect(sut.responds(to: selector)) == true
                    _ = sut.perform(selector, with: webView)
                }
            }
        }

        describe("JavaScript alert delegate") {

            it("should forward to uiDelegate while it is alive") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    let frame = fakeObject(WKFrameInfo.self)
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    var completionCallCount = 0

                    sut.webView(
                        webView,
                        runJavaScriptAlertPanelWithMessage: "message",
                        initiatedByFrame: frame
                    ) {
                        completionCallCount += 1
                    }

                    expect(mockUIDelegate.alertCallCount) == 1
                    expect(mockUIDelegate.receivedAlertWebView).to(beIdenticalTo(webView))
                    expect(mockUIDelegate.receivedAlertMessage) == "message"
                    expect(mockUIDelegate.receivedAlertFrame).to(beIdenticalTo(frame))
                    expect(completionCallCount) == 1
                }
            }

            it("should complete immediately after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    var mockUIDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    mockUIDelegate = nil
                    var completionCallCount = 0

                    sut.webView(
                        webView,
                        runJavaScriptAlertPanelWithMessage: "message",
                        initiatedByFrame: fakeObject(WKFrameInfo.self)
                    ) {
                        completionCallCount += 1
                    }

                    expect(completionCallCount) == 1
                }
            }
        }

        describe("JavaScript confirm delegate") {

            it("should forward to uiDelegate while it is alive") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    let frame = fakeObject(WKFrameInfo.self)
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    var completionCallCount = 0
                    var result = false

                    sut.webView(
                        webView,
                        runJavaScriptConfirmPanelWithMessage: "message",
                        initiatedByFrame: frame
                    ) {
                        completionCallCount += 1
                        result = $0
                    }

                    expect(mockUIDelegate.confirmCallCount) == 1
                    expect(mockUIDelegate.receivedConfirmWebView).to(beIdenticalTo(webView))
                    expect(mockUIDelegate.receivedConfirmMessage) == "message"
                    expect(mockUIDelegate.receivedConfirmFrame).to(beIdenticalTo(frame))
                    expect(completionCallCount) == 1
                    expect(result) == true
                }
            }

            it("should complete with false after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    var mockUIDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    mockUIDelegate = nil
                    var completionCallCount = 0
                    var result = true

                    sut.webView(
                        webView,
                        runJavaScriptConfirmPanelWithMessage: "message",
                        initiatedByFrame: fakeObject(WKFrameInfo.self)
                    ) {
                        completionCallCount += 1
                        result = $0
                    }

                    expect(completionCallCount) == 1
                    expect(result) == false
                }
            }
        }

        describe("JavaScript prompt delegate") {

            it("should intercept a Hackle prompt without forwarding to uiDelegate") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    mockInvocator.invocable = true
                    mockInvocator.invokeResult = "hackle-result"
                    var completionCallCount = 0
                    var result: String?

                    sut.webView(
                        webView,
                        runJavaScriptTextInputPanelWithPrompt: "hackle-prompt",
                        defaultText: "default",
                        initiatedByFrame: fakeObject(WKFrameInfo.self)
                    ) {
                        completionCallCount += 1
                        result = $0
                    }

                    expect(mockInvocator.invokedString) == "hackle-prompt"
                    expect(mockUIDelegate.promptCallCount) == 0
                    expect(completionCallCount) == 1
                    expect(result) == "hackle-result"
                }
            }

            it("should forward a non-Hackle prompt and all arguments to uiDelegate") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    let frame = fakeObject(WKFrameInfo.self)
                    let mockUIDelegate = MockWKUIDelegate()
                    mockUIDelegate.promptResult = "delegate-result"
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    var completionCallCount = 0
                    var result: String?

                    sut.webView(
                        webView,
                        runJavaScriptTextInputPanelWithPrompt: "normal-prompt",
                        defaultText: "default",
                        initiatedByFrame: frame
                    ) {
                        completionCallCount += 1
                        result = $0
                    }

                    expect(mockUIDelegate.promptCallCount) == 1
                    expect(mockUIDelegate.receivedPromptWebView).to(beIdenticalTo(webView))
                    expect(mockUIDelegate.receivedPrompt) == "normal-prompt"
                    expect(mockUIDelegate.receivedDefaultText) == "default"
                    expect(mockUIDelegate.receivedPromptFrame).to(beIdenticalTo(frame))
                    expect(completionCallCount) == 1
                    expect(result) == "delegate-result"
                }
            }

            it("should complete with nil exactly once after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    var mockUIDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    mockUIDelegate = nil
                    var completionCallCount = 0
                    var result: String? = "unexpected"

                    sut.webView(
                        webView,
                        runJavaScriptTextInputPanelWithPrompt: "normal-prompt",
                        defaultText: "default",
                        initiatedByFrame: fakeObject(WKFrameInfo.self)
                    ) {
                        completionCallCount += 1
                        result = $0
                    }

                    expect(completionCallCount) == 1
                    expect(result).to(beNil())
                }
            }
        }

        describe("createWebView delegate") {

            it("should forward to uiDelegate while it is alive") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    let popupWebView = WKWebView()
                    let configuration = WKWebViewConfiguration()
                    let navigationAction = fakeObject(WKNavigationAction.self)
                    let windowFeatures = fakeObject(WKWindowFeatures.self)
                    let mockUIDelegate = MockWKUIDelegate()
                    mockUIDelegate.createWebViewResult = popupWebView
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)

                    let createdWebView = sut.webView(
                        webView,
                        createWebViewWith: configuration,
                        for: navigationAction,
                        windowFeatures: windowFeatures
                    )

                    expect(mockUIDelegate.createWebViewCallCount) == 1
                    expect(mockUIDelegate.receivedCreateWebView).to(beIdenticalTo(webView))
                    expect(mockUIDelegate.receivedConfiguration).to(beIdenticalTo(configuration))
                    expect(mockUIDelegate.receivedNavigationAction).to(beIdenticalTo(navigationAction))
                    expect(mockUIDelegate.receivedWindowFeatures).to(beIdenticalTo(windowFeatures))
                    expect(createdWebView).to(beIdenticalTo(popupWebView))
                }
            }

            it("should return nil after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    var mockUIDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    mockUIDelegate = nil

                    let createdWebView = sut.webView(
                        webView,
                        createWebViewWith: WKWebViewConfiguration(),
                        for: fakeObject(WKNavigationAction.self),
                        windowFeatures: fakeObject(WKWindowFeatures.self)
                    )

                    expect(createdWebView).to(beNil())
                }
            }
        }
    }
}

// MARK: - Test Doubles

private class MockWKUIDelegate: NSObject, WKUIDelegate {
    var promptCallCount = 0
    var receivedPromptWebView: WKWebView?
    var receivedPrompt: String?
    var receivedDefaultText: String?
    var receivedPromptFrame: WKFrameInfo?
    var promptResult: String?
    var webViewDidCloseCallCount = 0
    var receivedClosedWebView: WKWebView?
    var alertCallCount = 0
    var receivedAlertWebView: WKWebView?
    var receivedAlertMessage: String?
    var receivedAlertFrame: WKFrameInfo?
    var confirmCallCount = 0
    var receivedConfirmWebView: WKWebView?
    var receivedConfirmMessage: String?
    var receivedConfirmFrame: WKFrameInfo?
    var createWebViewCallCount = 0
    var receivedCreateWebView: WKWebView?
    var receivedConfiguration: WKWebViewConfiguration?
    var receivedNavigationAction: WKNavigationAction?
    var receivedWindowFeatures: WKWindowFeatures?
    var createWebViewResult: WKWebView?

    @objc func customMethod() {}

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        createWebViewCallCount += 1
        receivedCreateWebView = webView
        receivedConfiguration = configuration
        receivedNavigationAction = navigationAction
        receivedWindowFeatures = windowFeatures
        return createWebViewResult
    }

    func webViewDidClose(_ webView: WKWebView) {
        webViewDidCloseCallCount += 1
        receivedClosedWebView = webView
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable () -> Void
    ) {
        alertCallCount += 1
        receivedAlertWebView = webView
        receivedAlertMessage = message
        receivedAlertFrame = frame
        MainActor.assumeIsolated {
            completionHandler()
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (Bool) -> Void
    ) {
        confirmCallCount += 1
        receivedConfirmWebView = webView
        receivedConfirmMessage = message
        receivedConfirmFrame = frame
        MainActor.assumeIsolated {
            completionHandler(true)
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (String?) -> Void
    ) {
        promptCallCount += 1
        receivedPromptWebView = webView
        receivedPrompt = prompt
        receivedDefaultText = defaultText
        receivedPromptFrame = frame
        MainActor.assumeIsolated {
            completionHandler(promptResult)
        }
    }
}

private class MinimalWKUIDelegate: NSObject, WKUIDelegate {
}

private func fakeObject<T: AnyObject>(_ type: T.Type) -> T {
    unsafeBitCast(NSObject(), to: type)
}

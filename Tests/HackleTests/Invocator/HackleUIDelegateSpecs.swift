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

                    expect(mockUIDelegate.webViewDidCloseCalled) == true
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
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    var completed = false

                    sut.webView(
                        webView,
                        runJavaScriptAlertPanelWithMessage: "message",
                        initiatedByFrame: fakeObject(WKFrameInfo.self)
                    ) {
                        completed = true
                    }

                    expect(mockUIDelegate.alertCalled) == true
                    expect(completed) == true
                }
            }

            it("should complete immediately after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    var mockUIDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    mockUIDelegate = nil
                    var completed = false

                    sut.webView(
                        webView,
                        runJavaScriptAlertPanelWithMessage: "message",
                        initiatedByFrame: fakeObject(WKFrameInfo.self)
                    ) {
                        completed = true
                    }

                    expect(completed) == true
                }
            }
        }

        describe("JavaScript confirm delegate") {

            it("should forward to uiDelegate while it is alive") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    var result = false

                    sut.webView(
                        webView,
                        runJavaScriptConfirmPanelWithMessage: "message",
                        initiatedByFrame: fakeObject(WKFrameInfo.self)
                    ) {
                        result = $0
                    }

                    expect(mockUIDelegate.confirmCalled) == true
                    expect(result) == true
                }
            }

            it("should complete with false after uiDelegate is deallocated") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    var mockUIDelegate: MockWKUIDelegate? = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    mockUIDelegate = nil
                    var result = true

                    sut.webView(
                        webView,
                        runJavaScriptConfirmPanelWithMessage: "message",
                        initiatedByFrame: fakeObject(WKFrameInfo.self)
                    ) {
                        result = $0
                    }

                    expect(result) == false
                }
            }
        }

        describe("createWebView delegate") {

            it("should forward to uiDelegate while it is alive") {
                MainActor.assumeIsolated {
                    let webView = WKWebView()
                    let popupWebView = WKWebView()
                    let mockUIDelegate = MockWKUIDelegate()
                    mockUIDelegate.createWebViewResult = popupWebView
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)

                    let createdWebView = sut.webView(
                        webView,
                        createWebViewWith: WKWebViewConfiguration(),
                        for: fakeObject(WKNavigationAction.self),
                        windowFeatures: fakeObject(WKWindowFeatures.self)
                    )

                    expect(mockUIDelegate.createWebViewCalled) == true
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
    var webViewDidCloseCalled = false
    var alertCalled = false
    var confirmCalled = false
    var createWebViewCalled = false
    var createWebViewResult: WKWebView?

    @objc func customMethod() {}

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        createWebViewCalled = true
        return createWebViewResult
    }

    func webViewDidClose(_ webView: WKWebView) {
        webViewDidCloseCalled = true
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable () -> Void
    ) {
        alertCalled = true
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
        confirmCalled = true
        MainActor.assumeIsolated {
            completionHandler(true)
        }
    }
}

private class MinimalWKUIDelegate: NSObject, WKUIDelegate {
}

private func fakeObject<T: AnyObject>(_ type: T.Type) -> T {
    unsafeBitCast(NSObject(), to: type)
}

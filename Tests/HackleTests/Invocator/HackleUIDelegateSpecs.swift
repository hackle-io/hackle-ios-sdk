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
                    expect(target as AnyObject).to(beIdenticalTo(sut as AnyObject))
                }
            }

            it("should return uiDelegate for selectors HackleUIDelegate does not handle") {
                MainActor.assumeIsolated {
                    let mockUIDelegate = MockWKUIDelegate()
                    let sut = HackleUIDelegate(invocator: mockInvocator, uiDelegate: mockUIDelegate)
                    let selector = #selector(MockWKUIDelegate.customMethod)
                    let target = sut.forwardingTarget(for: selector)
                    expect(target as AnyObject).to(beIdenticalTo(mockUIDelegate as AnyObject))
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

    @objc func customMethod() {}
}

private class MinimalWKUIDelegate: NSObject, WKUIDelegate {
}

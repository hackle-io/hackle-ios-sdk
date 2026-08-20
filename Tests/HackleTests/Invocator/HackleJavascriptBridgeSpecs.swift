//
//  HackleWebBridgeSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/29/25.
//

import Foundation
import Quick
import Nimble
import WebKit
@testable import Hackle

class HackleWebBridgeSpecs: QuickSpec {
    override class func spec() {
        let trackBody = #"{"_hackle":{"command":"track","parameters":{"event":"purchase"}}}"#

        describe("WKWebView+HackleJavascriptBridge") {

            var webView: WKWebView!
            var invocator: HackleInvocator!

            beforeEach {
                MainActor.assumeIsolated {
                    webView = WKWebView()
                }
                invocator = DefaultHackleInvocator(processor: MockInvocationProcessor())
            }

            describe("prepareForHackleWebBridge") {
                it("should add UserScript to webView") {
                    MainActor.assumeIsolated {
                        let config = HackleWebViewConfig.DEFAULT
                        let initialScriptCount = webView.configuration.userContentController.userScripts.count

                        webView.prepareForHackleJavascriptBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: config
                        )

                        let scripts = webView.configuration.userContentController.userScripts
                        expect(scripts.count) > initialScriptCount
                    }
                }

                it("should inject JavaScript bridge with getWebViewConfig function") {
                    MainActor.assumeIsolated {
                        let config = HackleWebViewConfig.builder()
                            .automaticScreenTracking(true)
                            .automaticEngagementTracking(false)
                            .build()

                        webView.prepareForHackleJavascriptBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: config
                        )

                        let scripts = webView.configuration.userContentController.userScripts
                        let hackleScript = scripts.first { $0.source.contains("/* Hackle:HackleJavascriptBridge */") }

                        expect(hackleScript).toNot(beNil())
                        expect(hackleScript?.source).to(contain("getWebViewConfig"))
                    }
                }

                it("should preserve existing UserScripts") {
                    MainActor.assumeIsolated {
                        let existingScript = WKUserScript(
                            source: "console.log('existing');",
                            injectionTime: .atDocumentStart,
                            forMainFrameOnly: true
                        )
                        webView.configuration.userContentController.addUserScript(existingScript)

                        let config = HackleWebViewConfig.DEFAULT

                        webView.prepareForHackleJavascriptBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: config
                        )

                        let scripts = webView.configuration.userContentController.userScripts
                        let existingScriptPresent = scripts.contains { $0.source.contains("console.log('existing')") }

                        expect(existingScriptPresent) == true
                    }
                }

                it("should include webViewConfig JSON string in script") {
                    MainActor.assumeIsolated {
                        let config = HackleWebViewConfig.builder()
                            .automaticRouteTracking(false)
                            .automaticScreenTracking(true)
                            .automaticEngagementTracking(false)
                            .build()

                        webView.prepareForHackleJavascriptBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: config
                        )

                        let scripts = webView.configuration.userContentController.userScripts
                        let hackleScript = scripts.first { $0.source.contains("getWebViewConfig") }

                        expect(hackleScript?.source).to(contain("automaticRouteTracking"))
                        expect(hackleScript?.source).to(contain("automaticScreenTracking"))
                        expect(hackleScript?.source).to(contain("automaticEngagementTracking"))
                    }
                }

                it("should assign independent HackleUIDelegate to each WKWebView") {
                    MainActor.assumeIsolated {
                        let webView1 = WKWebView()
                        let webView2 = WKWebView()
                        let config = HackleWebViewConfig.DEFAULT

                        webView1.prepareForHackleJavascriptBridge(
                            invocator: invocator, sdkKey: "key1", mode: .native, webViewConfig: config
                        )
                        webView2.prepareForHackleJavascriptBridge(
                            invocator: invocator, sdkKey: "key2", mode: .native, webViewConfig: config
                        )

                        expect(webView1.uiDelegate).toNot(beNil())
                        expect(webView2.uiDelegate).toNot(beNil())
                        expect(webView1.uiDelegate).toNot(beIdenticalTo(webView2.uiDelegate))
                    }
                }

                it("should replace previous Hackle UserScript when called multiple times") {
                    MainActor.assumeIsolated {
                        let config1 = HackleWebViewConfig.builder()
                            .automaticScreenTracking(true)
                            .build()

                        webView.prepareForHackleJavascriptBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: config1
                        )

                        let scriptsAfterFirst = webView.configuration.userContentController.userScripts
                        let hackleScriptCountAfterFirst = scriptsAfterFirst.filter { $0.source.contains("/* Hackle:HackleJavascriptBridge */") }.count

                        let config2 = HackleWebViewConfig.builder()
                            .automaticEngagementTracking(true)
                            .build()

                        webView.prepareForHackleJavascriptBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: config2
                        )

                        let scriptsAfterSecond = webView.configuration.userContentController.userScripts
                        let hackleScriptCountAfterSecond = scriptsAfterSecond.filter { $0.source.contains("/* Hackle:HackleJavascriptBridge */") }.count

                        // Hackle UserScript는 항상 1개만 존재해야 함
                        expect(hackleScriptCountAfterFirst) == 1
                        expect(hackleScriptCountAfterSecond) == 1
                    }
                }

                it("should expose bridge capabilities without changing invocationType") {
                    MainActor.assumeIsolated {
                        webView.prepareForHackleJavascriptBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: HackleWebViewConfig.DEFAULT
                        )

                        let scripts = webView.configuration.userContentController.userScripts
                        let hackleScript = scripts.first { $0.source.contains("/* Hackle:HackleJavascriptBridge */") }

                        // 구 js-sdk는 invocationType이 {prompt, function} 외면 throw한다. 이 값은 동결이다.
                        expect(hackleScript?.source).to(contain("getInvocationType: function() { return 'prompt' }"))
                        expect(hackleScript?.source).to(contain(#"getBridgeCapabilities: function() { return '["prompt","message"]' }"#))
                    }
                }

                it("should expose postMessage that forwards to the hackle message handler") {
                    MainActor.assumeIsolated {
                        webView.prepareForHackleJavascriptBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: HackleWebViewConfig.DEFAULT
                        )

                        let scripts = webView.configuration.userContentController.userScripts
                        let hackleScript = scripts.first { $0.source.contains("/* Hackle:HackleJavascriptBridge */") }

                        expect(hackleScript?.source).to(contain("postMessage: function(message) { window.webkit.messageHandlers.hackle.postMessage(message) }"))
                    }
                }

                it("should dispatch each message to its WebView invocator when userContentController is shared") {
                    MainActor.assumeIsolated {
                        let controller = MockUserContentController()
                        let configuration = WKWebViewConfiguration()
                        configuration.userContentController = controller
                        let firstWebView = WKWebView(frame: .zero, configuration: configuration)
                        let secondWebView = WKWebView(frame: .zero, configuration: configuration)
                        let firstInvocator = MockInvocator()
                        let secondInvocator = MockInvocator()

                        firstWebView.prepareForHackleJavascriptBridge(
                            invocator: firstInvocator, sdkKey: "key1", mode: .native, webViewConfig: .DEFAULT
                        )
                        secondWebView.prepareForHackleJavascriptBridge(
                            invocator: secondInvocator, sdkKey: "key2", mode: .native, webViewConfig: .DEFAULT
                        )
                        controller.send(MockScriptMessage(body: trackBody, webView: firstWebView))
                        controller.send(MockScriptMessage(body: trackBody, webView: secondWebView))

                        expect(firstInvocator.invokedStrings) == [trackBody]
                        expect(secondInvocator.invokedStrings) == [trackBody]
                        expect(controller.duplicatedHandlerNames).to(beEmpty())
                    }
                }

                it("should replace only the current WebView handler when applied repeatedly") {
                    MainActor.assumeIsolated {
                        let controller = MockUserContentController()
                        let configuration = WKWebViewConfiguration()
                        configuration.userContentController = controller
                        let targetWebView = WKWebView(frame: .zero, configuration: configuration)
                        let previousInvocator = MockInvocator()
                        let currentInvocator = MockInvocator()

                        targetWebView.prepareForHackleJavascriptBridge(
                            invocator: previousInvocator, sdkKey: "key1", mode: .native, webViewConfig: .DEFAULT
                        )
                        targetWebView.prepareForHackleJavascriptBridge(
                            invocator: currentInvocator, sdkKey: "key2", mode: .native, webViewConfig: .DEFAULT
                        )
                        controller.send(MockScriptMessage(body: trackBody, webView: targetWebView))

                        expect(previousInvocator.invokedStrings).to(beEmpty())
                        expect(currentInvocator.invokedStrings) == [trackBody]
                        expect(controller.duplicatedHandlerNames).to(beEmpty())
                    }
                }
            }
        }
    }
}

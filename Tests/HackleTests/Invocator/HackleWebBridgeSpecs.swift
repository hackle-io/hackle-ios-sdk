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
    override func spec() {
        describe("WKWebView+HackleWebBridge") {

            var webView: WKWebView!
            var invocator: HackleInvocator!

            beforeEach {
                MainActor.assumeIsolated {
                    webView = WKWebView()
                }
                invocator = DefaultHackleInvocator(hackleAppCore: MockHackleAppCore())
            }

            describe("prepareForHackleWebBridge") {
                it("should add UserScript to webView") {
                    MainActor.assumeIsolated {
                        let config = HackleWebViewConfig.DEFAULT
                        let initialScriptCount = webView.configuration.userContentController.userScripts.count

                        webView.prepareForHackleWebBridge(
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

                        webView.prepareForHackleWebBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: config
                        )

                        let scripts = webView.configuration.userContentController.userScripts
                        let hackleScript = scripts.first { $0.source.contains("/* Hackle App JavaScript Controller */") }

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

                        webView.prepareForHackleWebBridge(
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

                        webView.prepareForHackleWebBridge(
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

                        webView1.prepareForHackleWebBridge(
                            invocator: invocator, sdkKey: "key1", mode: .native, webViewConfig: config
                        )
                        webView2.prepareForHackleWebBridge(
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

                        webView.prepareForHackleWebBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: config1
                        )

                        let scriptsAfterFirst = webView.configuration.userContentController.userScripts
                        let hackleScriptCountAfterFirst = scriptsAfterFirst.filter { $0.source.contains("/* Hackle App JavaScript Controller */") }.count

                        let config2 = HackleWebViewConfig.builder()
                            .automaticEngagementTracking(true)
                            .build()

                        webView.prepareForHackleWebBridge(
                            invocator: invocator,
                            sdkKey: "test-sdk-key",
                            mode: .native,
                            webViewConfig: config2
                        )

                        let scriptsAfterSecond = webView.configuration.userContentController.userScripts
                        let hackleScriptCountAfterSecond = scriptsAfterSecond.filter { $0.source.contains("/* Hackle App JavaScript Controller */") }.count

                        // Hackle UserScript는 항상 1개만 존재해야 함
                        expect(hackleScriptCountAfterFirst) == 1
                        expect(hackleScriptCountAfterSecond) == 1
                    }
                }
            }
        }
    }
}

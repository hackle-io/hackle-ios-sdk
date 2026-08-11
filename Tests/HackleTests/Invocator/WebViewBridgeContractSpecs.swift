import Foundation
import MockingKit
import Nimble
import Quick
import WebKit
@testable import Hackle

/// 3 repo(iOS/Android/JS)가 공유하는 message 채널 wire 포맷 계약.
/// 여기의 payload 문자열은 스펙(§4)의 골든 픽스처다 — 임의로 바꾸지 말 것.
class WebViewBridgeContractSpecs: QuickSpec {
    override class func spec() {

        let requestId = "11111111-2222-3333-4444-555555555555"
        let mutationInvoke = "{\"_hackle\":{\"command\":\"setUser\",\"parameters\":{\"user\":{\"id\":\"42\"}}},\"requestId\":\"\(requestId)\"}"
        let trackInvoke = "{\"_hackle\":{\"command\":\"track\",\"parameters\":{\"event\":\"purchase\"}}}"

        var core: MockHackleAppCore!
        var invocator: DefaultHackleInvocator!
        var webView: MockWebView!

        beforeEach {
            core = MockHackleAppCore()
            invocator = DefaultHackleInvocator(
                processor: DefaultInvocationProcessor(handlerFactory: DefaultInvocationHandlerFactory(core: core))
            )
            MainActor.assumeIsolated {
                webView = MockWebView()
            }
        }

        it("requestId가 붙어도 기존 invocator가 그대로 파싱한다") {
            expect(invocator.isInvocableString(string: mutationInvoke)) == true
            expect(invocator.isInvocableString(string: trackInvoke)) == true

            let request = try InvocationRequest.parse(string: mutationInvoke)
            expect(request.command) == .setUser
            expect(request.parameters.userAsDictionary()?["id"] as? String) == "42"
        }

        it("mutation 메시지는 core를 호출하고 완료 후 resolve를 발송한다") {
            MainActor.assumeIsolated {
                let sut = HackleScriptMessageHandler(invocator: invocator)

                sut.handle(body: mutationInvoke, webView: webView)

                expect(core.setUserRef.invokations().count) == 1
                expect(core.setUserRef.firstInvokation().arguments.0.id) == "42"

                expect(webView.evaluatedScripts.count).toEventually(equal(1), timeout: .seconds(3))
                let script = webView.evaluatedScripts[0]
                expect(script).to(beginWith("window._hackleBridge && window._hackleBridge.resolve(\"\(requestId)\", \"{"))
                expect(script).to(contain("\\\"success\\\":true"))
                expect(script).to(endWith("}\")"))
            }
        }

        it("track 메시지는 core를 호출하고 회신하지 않는다") {
            MainActor.assumeIsolated {
                let sut = HackleScriptMessageHandler(invocator: invocator)

                sut.handle(body: trackInvoke, webView: webView)

                expect(core.trackRef.invokations().count) == 1
                expect(core.trackRef.firstInvokation().arguments.0.key) == "purchase"
                expect(webView.evaluatedScripts).to(beEmpty())
            }
        }
    }
}

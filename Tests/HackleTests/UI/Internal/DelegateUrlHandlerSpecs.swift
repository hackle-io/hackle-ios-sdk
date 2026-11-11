import Foundation
import Quick
import Nimble
@testable import Hackle

class DelegateUrlHandlerSpecs: QuickSpec {
    override class func spec() {
        describe("DelegateUrlHandler") {
            it("open은 url과 channel로 delegate를 1회 호출한다") {
                let delegate = MockHackleDelegate()
                let sut = DelegateUrlHandler(delegate: delegate)
                let url = URL(string: "myapp://home")!
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .inAppMessage)
                }
                expect(delegate.contexts.count) == 1
                expect(delegate.contexts[0].url) == url
                expect(delegate.contexts[0].channel) == .inAppMessage
            }
        }
    }
}

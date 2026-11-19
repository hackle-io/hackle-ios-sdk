import Foundation
import Nimble
import Quick
@testable import Hackle

class InAppMessageLinkPolicySpecs: QuickSpec {
    override class func spec() {
        it("allows web links and deep links") {
            let links = [
                "https://www.hackle.io",
                "http://example.com/path?a=b",
                "myapp://home",
                "tel:01012345678",
                "mailto:support@example.com",
                "itms-apps://itunes.apple.com/app/id123456789",
                "gogo",
            ]

            for link in links {
                expect(InAppMessageLinkPolicy.isAllowed(URL(string: link)!)).to(beTrue(), description: link)
            }
        }

        it("blocks schemes that run script or expose local content") {
            let links = [
                "javascript:alert(1)",
                "JavaScript:alert(1)",
                "file:///private/var/mobile/secret.txt",
                "data:text/html,hello",
                "blob:https://example.com/550e8400-e29b-41d4-a716-446655440000",
                "about:blank",
            ]

            for link in links {
                expect(InAppMessageLinkPolicy.isAllowed(URL(string: link)!)).to(beFalse(), description: link)
            }
        }
    }
}

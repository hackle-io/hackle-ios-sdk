import Foundation
import Quick
import Nimble
@testable import Hackle

class IdentifierSpecs: QuickSpec {
    override class func spec() {
        it("contains") {
            expect(["a": "b"].contains(type: "a", value: "b")) == true
            expect(["a": "b"].contains(type: "a", value: "a")) == false
            expect(["a": "b"].contains(type: "b", value: "b")) == false
        }
    }
}

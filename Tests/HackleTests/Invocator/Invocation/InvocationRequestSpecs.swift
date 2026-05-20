import Foundation
@testable import Hackle
import MockingKit
import Nimble
import Quick

class InvocationRequestSpecs: QuickSpec {
    override class func spec() {
        it("isInvocable") {
            expect(InvocationRequest.isInvocable(string: "{\"_hackle\":{\"command\":\"foo\"}}")) == true
            expect(InvocationRequest.isInvocable(string: "{\"_hackle\":{\"command\":\"\"}}")) == false
            expect(InvocationRequest.isInvocable(string: "{\"_hackle\":\"\"}}")) == false
            expect(InvocationRequest.isInvocable(string: "{\"_hackle\":{}}}")) == false
            expect(InvocationRequest.isInvocable(string: "{\"something\":{\"command\":\"\"}}")) == false
            expect(InvocationRequest.isInvocable(string: "{")) == false
            expect(InvocationRequest.isInvocable(string: "")) == false
        }

        describe("parse") {
            it("invalid") {
                expect(try InvocationRequest.parse(string: "not a json"))
                    .to(throwError(HackleError.error("Invalid invocation format")))
                expect(try InvocationRequest.parse(string: "{}"))
                    .to(throwError(HackleError.error("Invalid invocation format (missing: _hackle)")))
                expect(try InvocationRequest.parse(string: "{\"_hackle\":{}}"))
                    .to(throwError(HackleError.error("Invalid invocation format (missing: command)")))
                expect(try InvocationRequest.parse(string: "{\"_hackle\":{\"command\":\"invalidCommand\"}}"))
                    .to(throwError(HackleError.error("Unsupported InvocationCommand (invalidCommand)")))
            }

            it("valid") {
                let i1 = try InvocationRequest.parse(string: "{\"_hackle\":{\"command\":\"getSessionId\"}}")
                expect(i1.command).to(equal(.getSessionId))
                expect(i1.parameters).to(beEmpty())
                expect(i1.browserProperties).to(beEmpty())

                let i2 = try InvocationRequest.parse(string: "{\"_hackle\":{\"command\":\"setUserId\",\"parameters\":{\"userId\":\"user-id\"},\"browserProperties\":{\"url\":\"https://hackle.io\"}}}")
                expect(i2.command).to(equal(.setUserId))
                expect(i2.parameters["userId"] as? String).to(equal("user-id"))
                expect(i2.browserProperties["url"] as? String).to(equal("https://hackle.io"))
            }
        }
    }
}

import Foundation
@testable import Hackle
import MockingKit
import Nimble
import Quick

class InvocationResponseSpecs: QuickSpec {
    override func spec() {
        it("toJsonString") {
            expect(InvocationResponse<Any>.success().toJsonString())
                .to(contain("\"success\":true"))
                .to(contain("\"message\":\"OK\""))
            expect(InvocationResponse<Any>.error(error: HackleError.error("failed")).toJsonString())
                .to(contain("\"success\":false"))
                .to(contain("\"message\":\"failed\""))

            expect(InvocationResponse.success(data: "42").toJsonString()).to(contain("\"data\":\"42\""))
            expect(InvocationResponse.success(data: 42).toJsonString()).to(contain("\"data\":42"))
            expect(InvocationResponse.success(data: true).toJsonString()).to(contain("\"data\":true"))
            expect(InvocationResponse.success(data: ["key": "value"]).toJsonString()).to(contain("\"data\":{\"key\":\"value\"}"))
        }
    }
}

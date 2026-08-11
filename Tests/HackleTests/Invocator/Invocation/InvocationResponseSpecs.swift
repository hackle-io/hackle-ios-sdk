import Foundation
@testable import Hackle
import MockingKit
import Nimble
import Quick

class InvocationResponseSpecs: QuickSpec {
    override class func spec() {
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

        it("task는 mutation 응답만 가지며 json에 직렬화되지 않는다") {
            expect(InvocationResponse<Any>.success().task).to(beNil())
            expect(InvocationResponse.success(data: "42").task).to(beNil())
            expect(InvocationResponse<Any>.error(error: HackleError.error("failed")).task).to(beNil())

            let response = InvocationResponse<Any>.success(task: Task {})
            expect(response.task).toNot(beNil())
            expect(response.toJsonString()).to(contain("\"success\":true"))
            expect(response.toJsonString()).to(contain("\"message\":\"OK\""))
            expect(response.toJsonString()).toNot(contain("task"))
        }
    }
}

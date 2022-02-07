import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultUserValueResolverSpecs: QuickSpec {

    override func spec() {

        var sut: DefaultUserValueResolver!

        beforeEach {
            sut = DefaultUserValueResolver()
        }

        it("USER_ID") {
            let user = HackleUser.of(userId: "test_user_id")
            let actual = try sut.resolveOrNil(user: user, key: Target.Key(type: .userId, name: "USER_ID"))
            expect(actual as! String) == "test_user_id"
        }

        it("USER_PROPERTY") {
            let user = HackleUser.of(
                user: User(
                    id: "test_user_id",
                    properties: ["age": 42]
                ),
                hackleProperties: [:])
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .userProperty, name: "age")) as! Int) == 42
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .userProperty, name: "gradle"))).to(beNil())
        }

        it("HACKLE_PROPERTY") {
            let user = HackleUser.of(
                user: User(
                    id: "test_user_id",
                    properties: ["age": 42]
                ),
                hackleProperties: ["os": "test_os"])
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .hackleProperty, name: "os")) as! String) == "test_os"
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .hackleProperty, name: "os_version"))).to(beNil())
        }

        it("SEGMENT") {
            expect(try sut.resolveOrNil(user: HackleUser.of(userId: "test_user_id"), key: Target.Key(type: .segment, name: "SEGMENT")))
                .to(throwError(HackleError.error("Unsupported TargetKeyType [segment]")))
        }
    }
}

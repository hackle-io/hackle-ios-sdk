import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultUserValueResolverSpecs: QuickSpec {

    override func spec() {

        var sut: DefaultUserValueResolver!
        let user = HackleUser.of(
            user: Hackle.user(
                id: "test_id",
                userId: "test_user_id",
                deviceId: "test_device_id",
                identifiers: ["customId": "test_custom_id"],
                properties: ["age": 42]),
            hackleProperties: ["os": "test_os"])

        beforeEach {
            sut = DefaultUserValueResolver()
        }

        it("USER_ID") {
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .userId, name: "$id")) as! String) == "test_id"
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .userId, name: "$deviceId")) as! String) == "test_device_id"
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .userId, name: "$userId")) as! String) == "test_user_id"
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .userId, name: "customId")) as! String) == "test_custom_id"
        }

        it("USER_PROPERTY") {
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .userProperty, name: "age")) as! Int) == 42
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .userProperty, name: "gradle"))).to(beNil())
        }

        it("HACKLE_PROPERTY") {
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .hackleProperty, name: "os")) as! String) == "test_os"
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .hackleProperty, name: "os_version"))).to(beNil())
        }

        it("SEGMENT") {
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .eventProperty, name: "a"))).to(throwError())
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .segment, name: "a"))).to(throwError())
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .abTest, name: "a"))).to(throwError())
            expect(try sut.resolveOrNil(user: user, key: Target.Key(type: .featureFlag, name: "a"))).to(throwError())
        }
    }
}

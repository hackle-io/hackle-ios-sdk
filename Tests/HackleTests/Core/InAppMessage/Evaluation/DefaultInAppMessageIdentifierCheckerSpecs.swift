import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageIdentifierCheckerSpecs: QuickSpec {
    override func spec() {

        var sut: DefaultInAppMessageIdentifierChecker!
        beforeEach {
            sut = DefaultInAppMessageIdentifierChecker()
        }

        it("check") {
            verify(nil, nil, nil, nil, false)
            verify(nil, nil, nil, "c", false)
            verify(nil, nil, "c", nil, false)
            verify(nil, nil, "c", "c", false)
            verify(nil, nil, "c", "d", true)

            verify(nil, "a", nil, nil, false)
            verify(nil, "a", nil, "c", false)
            verify(nil, "a", "c", nil, false)
            verify(nil, "a", "c", "c", false)
            verify(nil, "a", "c", "d", true)

            verify("a", nil, nil, nil, false)
            verify("a", nil, nil, "c", false)
            verify("a", nil, "c", nil, false)
            verify("a", nil, "c", "c", false)
            verify("a", nil, "c", "d", true)

            verify("a", "a", nil, nil, false)
            verify("a", "a", nil, "c", false)
            verify("a", "a", "c", nil, false)
            verify("a", "a", "c", "c", false)
            verify("a", "a", "c", "d", false)

            verify("a", "b", nil, nil, true)
            verify("a", "b", nil, "c", true)
            verify("a", "b", "c", nil, true)
            verify("a", "b", "c", "c", true)
            verify("a", "b", "c", "d", true)
        }

        func verify(
            _ oldUserId: String?,
            _ newUserId: String?,
            _ oldDeviceId: String?,
            _ newDeviceId: String?,
            _ expected: Bool
        ) {
            let oldUser = User.builder()
                .userId(oldUserId)
                .deviceId(oldDeviceId)
                .build()

            let newUser = User.builder()
                .userId(newUserId)
                .deviceId(newDeviceId)
                .build()

            let actual = sut.isIdentifierChanged(old: oldUser.resolvedIdentifiers, new: newUser.resolvedIdentifiers)
            expect(actual) == expected
        }
    }


}

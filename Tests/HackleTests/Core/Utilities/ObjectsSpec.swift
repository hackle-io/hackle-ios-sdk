import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class ObjectsSpec: QuickSpec {
    override func spec() {
        it("to hex string") {
            let data = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
            expect(data.hexString()) == "000102030405060708090a0b0c0d0e0f"
            expect(data.hexString(separator: ":")) == "00:01:02:03:04:05:06:07:08:09:0a:0b:0c:0d:0e:0f"
        }
    }
}

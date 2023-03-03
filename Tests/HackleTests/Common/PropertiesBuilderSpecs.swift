import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class PropertiesBuilderSpecs: QuickSpec {

    override func spec() {
        it("valid raw value") {
            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", 1).build()).isEqual(to: ["key": 1])).to(beTrue())
            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", "1").build()).isEqual(to: ["key": "1"])).to(beTrue())
            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", true).build()).isEqual(to: ["key": true])).to(beTrue())
            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", false).build()).isEqual(to: ["key": false])).to(beTrue())
        }

        it("invalid raw value") {
            expect(PropertiesBuilder().add("key", nil).build().count) == 0
            expect(PropertiesBuilder().add("key", User.builder().build()).build().count) == 0
        }

        it("array value") {
            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", [1, 2, 3]).build()).isEqual(to: ["key": [1, 2, 3]])).to(beTrue())
            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", ["1", "2", "3"]).build()).isEqual(to: ["key": ["1", "2", "3"]])).to(beTrue())
            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", ["1", 2, "3"]).build()).isEqual(to: ["key": ["1", 2, "3"]])).to(beTrue())

            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", [1, 2, nil, 3]).build()).isEqual(to: ["key": [1, 2, 3]])).to(beTrue())
            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", [true, false]).build()).isEqual(to: ["key": []])).to(beTrue())

            expect(NSDictionary(dictionary: PropertiesBuilder().add("key", [String(repeating: "a", count: 1025)]).build()).isEqual(to: ["key": []])).to(beTrue())
        }
    }
}

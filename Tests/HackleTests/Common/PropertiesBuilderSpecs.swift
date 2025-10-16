import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class PropertiesBuilderSpecs: QuickSpec {

    func equals(_ p1: [String: Any], _ p2: [String: Any]) {
        expect(p1.count) == p2.count
        for (key, value) in p1 {
            expect(PropertyOperators.equals(value, p2[key] as Any)) == true
        }
    }

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

        it("max property size is 128") {
            let builder = PropertiesBuilder()
            for i in (1...128) {
                builder.add(String(i), i)
            }

            expect(builder.build().count) == 128
            expect(builder.add("key", 42).build().count) == 128
        }

        it("max key length is 128") {
            let builder = PropertiesBuilder()
            builder.add(String(repeating: "a", count: 128), 128)

            expect(builder.build().count) == 1

            builder.add(String(repeating: "a", count: 129), 129)
            expect(builder.build().count) == 1
        }

        it("properties") {
            let properties = [
                "k1": "v1",
                "k2": 2,
                "k3": true,
                "k4": false,
                "k5": [1, 2, 3],
                "k6": ["1", "2", "3"],
                "k7": nil
            ]

            let actual = PropertiesBuilder().add(properties).build()
            expect(actual.count) == 6
        }

        it("setOnce") {
            let properties = PropertiesBuilder()
                .add("a", 1)
                .add("a", 2)
                .add("b", 3)
                .add("b", 4, setOnce: true)
                .build()

            self.equals(properties, ["a": 2, "b": 3])
        }

        it("setOnce2") {
            let p1 = ["k1": 1, "k2": 1]
            let p2 = ["k1": 2, "k2": 2]

            self.equals(PropertiesBuilder().add(p1).add(p2).build(), ["k1": 2, "k2": 2])
            self.equals(PropertiesBuilder().add(p1).add(p2, setOnce: true).build(), ["k1": 1, "k2": 1])
        }

        it("add system properties") {
            let properties = PropertiesBuilder()
                .add("$set", ["age": 30])
                .add("set", ["age": 32])
                .build()
            expect(properties.count) == 1
            self.equals(properties["$set"] as! [String: Any], ["age": 30])
        }

        it("remove") {
            let properties = PropertiesBuilder()
                .add("age", 42)
                .remove("age")
                .build()

            expect(properties.count) == 0
        }

        it("remove properties") {
            let properties = PropertiesBuilder()
                .add("age", 42)
                .add("grade", "GOLD")
                .remove(["grade": "SILVER", "location": "Seoul"])
                .build()

            expect(properties.count) == 1
        }

        it("compute") {
            let properties = PropertiesBuilder()
                .add("age", 42)
                .add("grade", "GOLD")
                .compute("age") { it in
                    (it as! Int) + 42
                }
                .compute("grade") { it in
                    nil
                }
                .compute("location") { it in
                    "Seoul"
                }
                .compute("name") { it in
                    nil
                }
                .build()

            self.equals(properties, ["age": 84, "location": "Seoul"])
        }
    }
}

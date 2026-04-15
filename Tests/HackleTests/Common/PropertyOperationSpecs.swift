import Foundation
import Quick
import Nimble
@testable import Hackle

class PropertyOperationSpecs: QuickSpec {

    static func equals(_ p1: [String: Any], _ p2: [String: Any]) {
        expect(p1.count) == p2.count
        for (key, value) in p1 {
            expect(PropertyOperators.equals(value, p2[key] as Any)) == true
        }
    }

    override class func spec() {

        describe("PropertyOperation") {
            it("key") {
                expect(PropertyOperation.set.rawValue) == "$set"
                expect(PropertyOperation.setOnce.rawValue) == "$setOnce"
                expect(PropertyOperation.unset.rawValue) == "$unset"
                expect(PropertyOperation.increment.rawValue) == "$increment"
                expect(PropertyOperation.append.rawValue) == "$append"
                expect(PropertyOperation.appendOnce.rawValue) == "$appendOnce"
                expect(PropertyOperation.prepend.rawValue) == "$prepend"
                expect(PropertyOperation.prependOnce.rawValue) == "$prependOnce"
                expect(PropertyOperation.remove.rawValue) == "$remove"
                expect(PropertyOperation.clearAll.rawValue) == "$clearAll"
            }
        }

        describe("PropertyOperations") {
            it("empty") {
                expect(PropertyOperations.empty().count) == 0
            }

            it("clearAll") {
                let operations = PropertyOperations.clearAll()
                expect(operations.count) == 1
                expect(operations.contains(.clearAll)) == true
            }

            it("build") {
                let operations = PropertyOperations.builder()
                    .set("set1", 42)
                    .set("set2", ["a", "b"])
                    .set("set2", "set2")
                    .setOnce("setOnce", 43)
                    .unset("unset")
                    .increment("increment", 44)
                    .append("append", 45)
                    .appendOnce("appendOnce", 46)
                    .prepend("prepend", 47)
                    .prependOnce("prependOnce", 48)
                    .remove("remove", 49)
                    .clearAll()
                    .build()

                expect(operations.count) == 10

                func verify(_ operations: PropertyOperations, _ operation: PropertyOperation, _ properties: [String: Any]) {
                    let actual: [String: Any] = operations.asDictionary()[operation]!

                    expect(actual.count) == properties.count
                    for (key, value) in properties {
                        expect(PropertyOperators.equals(actual[key] as Any, value)) == true
                    }
                }

                verify(operations, .set, ["set1": 42, "set2": ["a", "b"]])
                verify(operations, .setOnce, ["setOnce": 43])
                verify(operations, .unset, ["unset": "-"])
                verify(operations, .increment, ["increment": 44])
                verify(operations, .append, ["append": 45])
                verify(operations, .appendOnce, ["appendOnce": 46])
                verify(operations, .prepend, ["prepend": 47])
                verify(operations, .prependOnce, ["prependOnce": 48])
                verify(operations, .remove, ["remove": 49])
                verify(operations, .clearAll, ["clearAll": "-"])
            }

            it("toEvent") {
                let operations = PropertyOperations.builder()
                    .set("set1", 42)
                    .set("set2", ["a", "b"])
                    .set("set2", "set2")
                    .setOnce("setOnce", 43)
                    .unset("unset")
                    .increment("increment", 44)
                    .append("append", 45)
                    .appendOnce("appendOnce", 46)
                    .prepend("prepend", 47)
                    .prependOnce("prependOnce", 48)
                    .remove("remove", 49)
                    .clearAll()
                    .build()

                let event = operations.toEvent()

                expect(event.key) == "$properties"

                equals(event.properties!["$set"] as! [String: Any], ["set1": 42, "set2": ["a", "b"]])
                equals(event.properties!["$setOnce"] as! [String: Any], ["setOnce": 43])
                equals(event.properties!["$unset"] as! [String: Any], ["unset": "-"])
                equals(event.properties!["$increment"] as! [String: Any], ["increment": 44])
                equals(event.properties!["$append"] as! [String: Any], ["append": 45])
                equals(event.properties!["$appendOnce"] as! [String: Any], ["appendOnce": 46])
                equals(event.properties!["$prepend"] as! [String: Any], ["prepend": 47])
                equals(event.properties!["$prependOnce"] as! [String: Any], ["prependOnce": 48])
                equals(event.properties!["$remove"] as! [String: Any], ["remove": 49])
                equals(event.properties!["$clearAll"] as! [String: Any], ["clearAll": "-"])
            }
        }
    }
}

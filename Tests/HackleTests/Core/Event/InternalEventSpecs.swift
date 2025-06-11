//
//  InternalEventSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/11/25.
//

import Quick
import Nimble
@testable import Hackle

class InternalEventSpecs: QuickSpec {
    override func spec() {

        describe("InternalEvent initialization") {

            it("should assign key, value, properties, and internalProperties correctly") {
                let event = InternalEvent(
                    key: "testKey",
                    value: 123.0,
                    properties: ["a": 1, "b": "str"],
                    internalProperties: ["x": true, "y": 999]
                )
                expect(event.key) == "testKey"
                expect(event.value) == 123.0
                expect(event.properties?["a"] as? Int) == 1
                expect(event.properties?["b"] as? String) == "str"
                expect(event.internalProperties?["x"] as? Bool) == true
                expect(event.internalProperties?["y"] as? Int) == 999
            }

            it("should set value and properties to nil if not provided") {
                let event = InternalEvent(key: "noValue")
                expect(event.value).to(beNil())
                expect(event.properties).to(beNil())
                expect(event.internalProperties).to(beNil())
            }

            it("should handle edge Double values") {
                let values: [Double] = [
                    0.0,
                    1.2345,
                    -9876.54321,
                    999999999999999.999999,
                    -999999999999999.999999,
                    Double.nan,
                    Double.infinity,
                    -Double.infinity,
                    Double.greatestFiniteMagnitude,
                    Double.leastNormalMagnitude
                ]

                for value in values {
                    let event = InternalEvent(key: "conversionCheck", value: value)
                    let nsValue = event.value?.doubleValue

                    if value.isNaN {
                        expect(nsValue?.isNaN) == true
                    } else if value.isInfinite {
                        expect(nsValue?.isInfinite) == true
                        expect(nsValue) == value
                    } else {
                        expect(nsValue) == value
                    }
                }
            }
        }

        describe("HackleInternalEventBuilder functionality") {

            it("should build an InternalEvent with correct values") {
                let builder = HackleInternalEventBuilder(key: "builderKey")
                    .value(42.0)
                    .property("foo", "bar")
                    .property("num", 10)
                    .internalProperty("internalA", "secret")
                    .internalProperty("internalB", 100)
                let event = builder.build()
                expect(event.key) == "builderKey"
                expect(event.value) == 42.0
                expect(event.properties?["foo"] as? String) == "bar"
                expect(event.properties?["num"] as? Int) == 10
                expect(event.internalProperties?["internalA"] as? String) == "secret"
                expect(event.internalProperties?["internalB"] as? Int) == 100
            }

            it("should accumulate properties and internalProperties from multiple calls") {
                let builder = HackleInternalEventBuilder(key: "multiKey")
                    .properties(["a": 1])
                    .property("b", 2)
                    .properties(["c": 3])
                    .internalProperty("x", true)
                    .internalProperty("y", 999)
                let event = builder.build()
                expect(event.properties?["a"] as? Int) == 1
                expect(event.properties?["b"] as? Int) == 2
                expect(event.properties?["c"] as? Int) == 3
                expect(event.internalProperties?["x"] as? Bool) == true
                expect(event.internalProperties?["y"] as? Int) == 999
            }

            it("should allow building with only key") {
                let builder = HackleInternalEventBuilder(key: "onlyKey")
                let event = builder.build()
                expect(event.key) == "onlyKey"
                expect(event.value).to(beNil())
                expect(event.properties?.isEmpty ?? true).to(beTrue())
                expect(event.internalProperties?.isEmpty ?? true).to(beTrue())
            }
        }
    }
}

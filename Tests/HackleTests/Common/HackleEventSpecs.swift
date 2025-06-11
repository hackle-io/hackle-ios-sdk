//
//  HackleEventSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/11/25.
//

import Quick
import Nimble
@testable import Hackle

class EventSpecs: QuickSpec {
    override func spec() {

        describe("Event initialization") {

            it("should assign key, value, and properties correctly") {
                let event = Event(key: "testKey", value: 123.0, properties: ["a": 1, "b": "str"])
                expect(event.key) == "testKey"
                expect(event.value) == 123.0
                expect(event.properties?["a"] as? Int) == 1
                expect(event.properties?["b"] as? String) == "str"
                expect(event.internalProperties).to(beNil())
            }

            it("should set value to nil if not provided") {
                let event = Event(key: "noValue")
                expect(event.value).to(beNil())
            }

            it("should handle properties being nil") {
                let event = Event(key: "key", value: 1.0, properties: nil)
                expect(event.properties).to(beNil())
            }
            
            it("value range check") {
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
                    let event = Event(key: "conversionCheck", value: value)
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

        describe("HackleEventBuilder functionality") {

            it("should build an Event with correct values") {
                let builder = HackleEventBuilder(key: "builderKey")
                    .value(42.0)
                    .property("foo", "bar")
                    .property("num", 10)
                let event = builder.build()
                expect(event.key) == "builderKey"
                expect(event.value) == 42.0
                expect(event.properties?["foo"] as? String) == "bar"
                expect(event.properties?["num"] as? Int) == 10
            }

            it("should accumulate properties from multiple calls") {
                let builder = HackleEventBuilder(key: "multiKey")
                    .properties(["a": 1])
                    .property("b", 2)
                    .properties(["c": 3])
                let event = builder.build()
                expect(event.properties?["a"] as? Int) == 1
                expect(event.properties?["b"] as? Int) == 2
                expect(event.properties?["c"] as? Int) == 3
            }

            it("should allow building with only key") {
                let builder = HackleEventBuilder(key: "onlyKey")
                let event = builder.build()
                expect(event.key) == "onlyKey"
                expect(event.value).to(beNil())
                expect(event.properties?.isEmpty ?? true).to(beTrue())
            }
        }
    }
}

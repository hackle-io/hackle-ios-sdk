//
//  HackleValueSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/03/03.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class HackleValueSpecs: QuickSpec {
    override func spec() {

        it("stringValue") {
            expect(HackleValue.string("42").stringOrNil) == "42"
            expect(HackleValue.int(42).stringOrNil).to(beNil())
            expect(HackleValue.double(42.42).stringOrNil).to(beNil())
            expect(HackleValue.bool(true).stringOrNil).to(beNil())
            expect(HackleValue.null.stringOrNil).to(beNil())
        }

        it("intValue") {
            expect(HackleValue.string("42").intOrNil).to(beNil())
            expect(HackleValue.int(42).intOrNil) == 42
            expect(HackleValue.double(42.42).intOrNil) == 42
            expect(HackleValue.bool(true).intOrNil).to(beNil())
            expect(HackleValue.null.intOrNil).to(beNil())
        }

        it("doubleValue") {
            expect(HackleValue.string("42").doubleOrNil).to(beNil())
            expect(HackleValue.int(42).doubleOrNil) == 42.0
            expect(HackleValue.double(42.42).doubleOrNil) == 42.42
            expect(HackleValue.bool(true).doubleOrNil).to(beNil())
            expect(HackleValue.null.doubleOrNil).to(beNil())
        }

        it("boolValue") {
            expect(HackleValue.string("42").boolOrNil).to(beNil())
            expect(HackleValue.int(42).boolOrNil).to(beNil())
            expect(HackleValue.double(42.42).boolOrNil).to(beNil())
            expect(HackleValue.bool(true).boolOrNil) == true
            expect(HackleValue.null.boolOrNil).to(beNil())
        }

        it("asString") {
            expect(HackleValue(value: "42").asString()) == "42"
            expect(HackleValue(value: Int32(42)).asString()) == "42"
            expect(HackleValue(value: Int64(42)).asString()) == "42"
            expect(HackleValue(value: Double(42.0)).asString()) == "42.0"
            expect(HackleValue(value: Double(42.42)).asString()) == "42.42"
            expect(HackleValue(value: true).asString()).to(beNil())
        }

        it("asDouble") {
            expect(HackleValue(value: Int32(42)).asDouble()) == 42.0
            expect(HackleValue(value: Int64(42)).asDouble()) == 42.0
            expect(HackleValue(value: Double(42.0)).asDouble()) == 42.0
            expect(HackleValue(value: Double(42.42)).asDouble()) == 42.42

            expect(HackleValue(value: "42").asDouble()) == 42.0
            expect(HackleValue(value: "42.0").asDouble()) == 42.0
            expect(HackleValue(value: "42.42").asDouble()) == 42.42
        }
        
        it("asBool") {
            expect(HackleValue(value: "true").asBool()) == true
            expect(HackleValue(value: "TRUE").asBool()) == true
            expect(HackleValue(value: "false").asBool()) == false
            expect(HackleValue(value: "FALSE").asBool()) == false
            
            expect(HackleValue(value: "trues").asBool()).to(beNil())
            expect(HackleValue(value: "strings").asBool()).to(beNil())
        }

        it("decode") {
            expect(try! JSONDecoder().decode(HackleValue.self, from: "\"42\"".data(using: .utf8)!)) == .string("42")
            expect(try! JSONDecoder().decode(HackleValue.self, from: "42".data(using: .utf8)!)) == .int(42)
            expect(try! JSONDecoder().decode(HackleValue.self, from: "42.0".data(using: .utf8)!)) == .int(42)
            expect(try! JSONDecoder().decode(HackleValue.self, from: "42.42".data(using: .utf8)!)) == .double(42.42)
            expect(try! JSONDecoder().decode(HackleValue.self, from: "true".data(using: .utf8)!)) == .bool(true)
        }

        it("encode") {
            expect(String(data: try! JSONEncoder().encode(HackleValue.string("42")), encoding: .utf8)) == "\"42\""
            expect(String(data: try! JSONEncoder().encode(HackleValue.int(42)), encoding: .utf8)) == "42"
            expect(String(data: try! JSONEncoder().encode(HackleValue.double(42.25)), encoding: .utf8)) == "42.25"
            expect(String(data: try! JSONEncoder().encode(HackleValue.bool(true)), encoding: .utf8)) == "true"
        }
    }
}

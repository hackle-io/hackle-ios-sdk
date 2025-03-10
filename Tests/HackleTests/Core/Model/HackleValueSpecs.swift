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
        
            expect(HackleValue.int(1).intOrNil) == 1
            expect(HackleValue(value: 1).asDouble()) == 1
            expect(HackleValue.int(0).intOrNil) == 0
            expect(HackleValue(value: 0).asDouble()) == 0
            
            expect(HackleValue(value: Int64.max).intOrNil) == Int64.max
            expect(HackleValue(value: Int64.min).intOrNil) == Int64.min
     
        }

        it("doubleValue") {
            expect(HackleValue.string("42").doubleOrNil).to(beNil())
            expect(HackleValue.int(42).doubleOrNil) == 42.0
            expect(HackleValue.double(42.42).doubleOrNil) == 42.42
            expect(HackleValue.bool(true).doubleOrNil).to(beNil())
            expect(HackleValue.null.doubleOrNil).to(beNil())
            
            expect(HackleValue.double(1).doubleOrNil) == 1
            expect(HackleValue(value: 1).asDouble()) == 1
            expect(HackleValue.double(0).doubleOrNil) == 0
            expect(HackleValue(value: 0).asDouble()) == 0
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
            expect(HackleValue(value: true).asString()) == "true"
            expect(HackleValue(value: false).asString()) == "false"
        }

        it("asDouble") {
            expect(HackleValue(value: Int32(42)).asDouble()) == 42.0
            expect(HackleValue(value: Int64(42)).asDouble()) == 42.0
            expect(HackleValue(value: Double(42.0)).asDouble()) == 42.0
            expect(HackleValue(value: Double(42.42)).asDouble()) == 42.42

            expect(HackleValue(value: "42").asDouble()) == 42.0
            expect(HackleValue(value: "42.0").asDouble()) == 42.0
            expect(HackleValue(value: "42.42").asDouble()) == 42.42
            
            expect(HackleValue.int(1).boolOrNil).to(beNil())
            expect(HackleValue(value: 1).asBool()).to(beNil())
            expect(HackleValue.int(0).boolOrNil).to(beNil())
            expect(HackleValue(value: 0).asBool()).to(beNil())
            
            expect(HackleValue.string("1").asBool()).to(beNil())
            expect(HackleValue.string("0").asBool()).to(beNil())
            expect(HackleValue(value: "1").asBool()).to(beNil())
            expect(HackleValue(value: "0").asBool()).to(beNil())
        }
        
        it("asBool") {
            expect(HackleValue(value: "true").asBool()) == true
            expect(HackleValue(value: "false").asBool()) == false
            
            expect(HackleValue(value: "TRUE").asBool()).to(beNil())
            expect(HackleValue(value: "FALSE").asBool()).to(beNil())
            expect(HackleValue(value: "trues").asBool()).to(beNil())
            expect(HackleValue(value: "strings").asBool()).to(beNil())
            
            let cfBooleanTrue: CFBoolean = true as CFBoolean // like 1
            let cfBooleanFalse: CFBoolean = false as CFBoolean // like 0
            expect(HackleValue(value: cfBooleanTrue).asBool()) == true
            expect(HackleValue(value: cfBooleanFalse).asBool()) == false
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
        
        it("check boolean in json case") {
            func v(_ value: Any) -> Any {
                let tmp = ["tmp": value]
                let data = Json.serialize(tmp)!
                let dict = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
                return dict["tmp"]!
            }
            
            expect(HackleValue(value: v(true)).asBool()) == true
            expect(HackleValue(value: v(false)).asBool()) == false
            expect(HackleValue(value: v("true")).asBool()) == true
            expect(HackleValue(value: v("false")).asBool()) == false
            expect(HackleValue(value: v(0)).asBool()).to(beNil())
            expect(HackleValue(value: v(1)).asBool()).to(beNil())
            expect(HackleValue(value: v(1)).asDouble()) == 1
            expect(HackleValue(value: v(0)).asDouble()) == 0
            expect(HackleValue(value: v(NSNumber(true))).asBool()) == true
            expect(HackleValue(value: v(NSNumber(false))).asBool()) == false
            expect(HackleValue(value: v(NSNumber(0))).asDouble()) == 0
            expect(HackleValue(value: v(NSNumber(1))).asDouble()) == 1
            expect(HackleValue(value: v(NSNumber(0))).asBool()).to(beNil())
            expect(HackleValue(value: v(NSNumber(1))).asBool()).to(beNil())
        }
        
        it("check is boolean") {
            let cfBooleanTrue: CFBoolean = true as CFBoolean // like 1
            let cfBooleanFalse: CFBoolean = false as CFBoolean // like 0
            
            expect(Objects.isBoolType(true)) == true
            expect(Objects.isBoolType(false)) == true
           
            expect(Objects.isBoolType(cfBooleanTrue)) == true
            expect(Objects.isBoolType(cfBooleanFalse)) == true
            
            expect(Objects.isBoolType(0)) == false
            expect(Objects.isBoolType(1)) == false
            expect(Objects.isBoolType(999)) == false
            
            expect(Objects.isBoolType(NSNumber(0))) == false
            expect(Objects.isBoolType(NSNumber(1))) == false
            
            expect(Objects.isBoolType(NSNumber(true))) == true
            expect(Objects.isBoolType(NSNumber(false))) == true
            
            expect(Objects.asBoolOrNil(NSNumber(0))).to(beNil())
            expect(Objects.asBoolOrNil(NSNumber(1))).to(beNil())
            expect(Objects.asBoolOrNil(NSNumber(true))) == true
            expect(Objects.asBoolOrNil(NSNumber(false))) == false
        }
    }
}

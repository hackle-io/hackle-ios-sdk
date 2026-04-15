import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class ValueMatcherSpecs: QuickSpec {
    override class func spec() {

        describe("StringMatcher") {
            let sut = StringMatcher()
            

            it("string type match") {
                verifyIn(sut: sut, userValue: "42", matchValue: HackleValue(value: "42"), expected: true)
                verifyIn(sut: sut, userValue: "42.42", matchValue: HackleValue(value: "42.42"), expected: true)
                verifyContains(sut: sut, userValue: "42", matchValue: HackleValue(value: "4"), expected: true)
                verifyStartsWith(sut: sut, userValue: "42", matchValue: HackleValue(value: "4"), expected: true)
                verifyEndsWith(sut: sut, userValue: "42", matchValue: HackleValue(value: "2"), expected: true)
                verifyGreaterThan(sut: sut, userValue: "42", matchValue: HackleValue(value: "41"), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: "42", matchValue: HackleValue(value: "42"), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: "43", matchValue: HackleValue(value: "42"), expected: true)
                verifyLessThan(sut: sut, userValue: "42", matchValue: HackleValue(value: "43"), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: "42", matchValue: HackleValue(value: "42"), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: "41", matchValue: HackleValue(value: "42"), expected: true)
            }
            
            it("matchValue가 자료형이 아니면 항상 false") {
                verifyIn(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
                verifyContains(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
                verifyStartsWith(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
                verifyEndsWith(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
                verifyGreaterThan(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
                verifyLessThan(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
            }
            
            it("userValue가 자료형이 아니면 항상 false") {
                verifyIn(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
                verifyContains(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
                verifyStartsWith(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
                verifyEndsWith(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
                verifyGreaterThan(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
                verifyLessThan(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
            }

            it("number 타입이면 캐스팅 후 match") {
                verifyIn(sut: sut, userValue: "42", matchValue: HackleValue(value: 42), expected: true)
                verifyIn(sut: sut, userValue: 42, matchValue: HackleValue(value: "42"), expected: true)
                verifyIn(sut: sut, userValue: 42, matchValue: HackleValue(value: 42), expected: true)
                
                verifyIn(sut: sut, userValue: "42.42", matchValue: HackleValue(value: 42.42), expected: true)
                verifyIn(sut: sut, userValue: 42.42, matchValue: HackleValue(value: "42.42"), expected: true)
                verifyIn(sut: sut, userValue: 42.42, matchValue: HackleValue(value: 42.42), expected: true)
            }

            it("bool 타입이면 캐스팅 후 match") {
                verifyIn(sut: sut, userValue: "true", matchValue: HackleValue(value: true), expected: true)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "true"), expected: true)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: true)
                verifyIn(sut: sut, userValue: "false", matchValue: HackleValue(value: false), expected: true)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: "false"), expected: true)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: false), expected: true)
            }

            it("지원하지 않는 type") {
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "1"), expected: false)
                verifyIn(sut: sut, userValue: "1", matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: "0"), expected: false)
                verifyIn(sut: sut, userValue: "0", matchValue: HackleValue(value: false), expected: false)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "TRUE"), expected: false)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: "FALSE"), expected: false)
            }
        }

        describe("NumberMatcher") {
            let sut = NumberMatcher()

            it("number type") {
                verifyIn(sut: sut, userValue: 42, matchValue: HackleValue(value: 42), expected: true)
                verifyIn(sut: sut, userValue: 42.1, matchValue: HackleValue(value: 42.1), expected: true)
                verifyIn(sut: sut, userValue: 42.0, matchValue: HackleValue(value: 42), expected: true)
                verifyIn(sut: sut, userValue: 42, matchValue: HackleValue(value: 42.0), expected: true)
                verifyIn(sut: sut, userValue: 0, matchValue: HackleValue(value: 0.0), expected: true)
                verifyIn(sut: sut, userValue: Int64(42), matchValue: HackleValue(value: 42), expected: true)
                verifyIn(sut: sut, userValue: Int64(42), matchValue: HackleValue(value: 42.0), expected: true)
                verifyIn(sut: sut, userValue: 42, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyIn(sut: sut, userValue: 42.0, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyIn(sut: sut, userValue: Double(42.0), matchValue: HackleValue(value: 42), expected: true)
                verifyIn(sut: sut, userValue: Double(42.1), matchValue: HackleValue(value: 42.1), expected: true)
                verifyIn(sut: sut, userValue: 42.0, matchValue: HackleValue(value: Double(42.0)), expected: true)
                verifyIn(sut: sut, userValue: 42.1, matchValue: HackleValue(value: Double(42.1)), expected: true)

                verifyGreaterThan(sut: sut, userValue: 43, matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThan(sut: sut, userValue: 43.1, matchValue: HackleValue(value: 42.1), expected: true)
                verifyGreaterThan(sut: sut, userValue: 43.0, matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThan(sut: sut, userValue: 43, matchValue: HackleValue(value: 42.0), expected: true)
                verifyGreaterThan(sut: sut, userValue: 1, matchValue: HackleValue(value: 0.0), expected: true)
                verifyGreaterThan(sut: sut, userValue: Int64(43), matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThan(sut: sut, userValue: Int64(43), matchValue: HackleValue(value: 42.0), expected: true)
                verifyGreaterThan(sut: sut, userValue: 43, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyGreaterThan(sut: sut, userValue: 43.0, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyGreaterThan(sut: sut, userValue: Double(43.0), matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThan(sut: sut, userValue: Double(43.1), matchValue: HackleValue(value: 42.1), expected: true)
                verifyGreaterThan(sut: sut, userValue: 43.0, matchValue: HackleValue(value: Double(42.0)), expected: true)
                verifyGreaterThan(sut: sut, userValue: 43.1, matchValue: HackleValue(value: Double(42.1)), expected: true)
                
                verifyGreaterThanOrEqual(sut: sut, userValue: 42, matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 42.1, matchValue: HackleValue(value: 42.1), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 42.0, matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 42, matchValue: HackleValue(value: 42.0), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 0, matchValue: HackleValue(value: 0.0), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: Int64(42), matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: Int64(42), matchValue: HackleValue(value: 42.0), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 42, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 42.0, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: Double(42.0), matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: Double(42.1), matchValue: HackleValue(value: 42.1), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 42.0, matchValue: HackleValue(value: Double(42.0)), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 42.1, matchValue: HackleValue(value: Double(42.1)), expected: true)
                
                verifyGreaterThanOrEqual(sut: sut, userValue: 43, matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 43.1, matchValue: HackleValue(value: 42.1), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 43.0, matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 43, matchValue: HackleValue(value: 42.0), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 1, matchValue: HackleValue(value: 0.0), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: Int64(43), matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: Int64(43), matchValue: HackleValue(value: 42.0), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 43, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 43.0, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: Double(43.0), matchValue: HackleValue(value: 42), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: Double(43.1), matchValue: HackleValue(value: 42.1), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 43.0, matchValue: HackleValue(value: Double(42.0)), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: 43.1, matchValue: HackleValue(value: Double(42.1)), expected: true)
                
                verifyLessThan(sut: sut, userValue: 41, matchValue: HackleValue(value: 42), expected: true)
                verifyLessThan(sut: sut, userValue: 41.1, matchValue: HackleValue(value: 42.1), expected: true)
                verifyLessThan(sut: sut, userValue: 41.0, matchValue: HackleValue(value: 42), expected: true)
                verifyLessThan(sut: sut, userValue: 41, matchValue: HackleValue(value: 42.0), expected: true)
                verifyLessThan(sut: sut, userValue: -1, matchValue: HackleValue(value: 0.0), expected: true)
                verifyLessThan(sut: sut, userValue: Int64(41), matchValue: HackleValue(value: 42), expected: true)
                verifyLessThan(sut: sut, userValue: Int64(41), matchValue: HackleValue(value: 42.0), expected: true)
                verifyLessThan(sut: sut, userValue: 41, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyLessThan(sut: sut, userValue: 41.0, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyLessThan(sut: sut, userValue: Double(41.0), matchValue: HackleValue(value: 42), expected: true)
                verifyLessThan(sut: sut, userValue: Double(41.1), matchValue: HackleValue(value: 42.1), expected: true)
                verifyLessThan(sut: sut, userValue: 41.0, matchValue: HackleValue(value: Double(42.0)), expected: true)
                verifyLessThan(sut: sut, userValue: 41.1, matchValue: HackleValue(value: Double(42.1)), expected: true)
                
                verifyLessThanOrEqual(sut: sut, userValue: 41, matchValue: HackleValue(value: 42), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 41.1, matchValue: HackleValue(value: 42.1), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 41.0, matchValue: HackleValue(value: 42), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 41, matchValue: HackleValue(value: 42.0), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: -1, matchValue: HackleValue(value: 0.0), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: Int64(41), matchValue: HackleValue(value: 42), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: Int64(41), matchValue: HackleValue(value: 42.0), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 41, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 41.0, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: Double(41.0), matchValue: HackleValue(value: 42), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: Double(41.1), matchValue: HackleValue(value: 42.1), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 41.0, matchValue: HackleValue(value: Double(42.0)), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 41.1, matchValue: HackleValue(value: Double(42.1)), expected: true)
                
                verifyLessThanOrEqual(sut: sut, userValue: 42, matchValue: HackleValue(value: 42), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 42.1, matchValue: HackleValue(value: 42.1), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 42.0, matchValue: HackleValue(value: 42), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 42, matchValue: HackleValue(value: 42.0), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 0, matchValue: HackleValue(value: 0.0), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: Int64(42), matchValue: HackleValue(value: 42), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: Int64(42), matchValue: HackleValue(value: 42.0), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 42, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 42.0, matchValue: HackleValue(value: Int64(42)), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: Double(42.0), matchValue: HackleValue(value: 42), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: Double(42.1), matchValue: HackleValue(value: 42.1), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 42.0, matchValue: HackleValue(value: Double(42.0)), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: 42.1, matchValue: HackleValue(value: Double(42.1)), expected: true)
            }
            
            it("숫자형 범위 체크") {
                verifyIn(sut: sut, userValue: Int32.max, matchValue: HackleValue(value: Int32.max), expected: true)
                verifyIn(sut: sut, userValue: Int32.min, matchValue: HackleValue(value: Int32.min), expected: true)
                verifyIn(sut: sut, userValue: 2^53, matchValue: HackleValue(value: 2^53), expected: true)
                verifyIn(sut: sut, userValue: -2^53, matchValue: HackleValue(value: -2^53), expected: true)
                verifyIn(sut: sut, userValue: Double(Int32.max), matchValue: HackleValue(value: Int32.max), expected: true)
                verifyIn(sut: sut, userValue: Double(Int32.min), matchValue: HackleValue(value: Int32.min), expected: true)
                verifyIn(sut: sut, userValue: Double(2^53), matchValue: HackleValue(value: 2^53), expected: true)
                verifyIn(sut: sut, userValue: Double(-2^53), matchValue: HackleValue(value: -2^53), expected: true)
                verifyIn(sut: sut, userValue: Double.zero, matchValue: HackleValue(value: Int32.zero), expected: true)
                verifyIn(sut: sut, userValue: Double.zero, matchValue: HackleValue(value: Int64.zero), expected: true)
                verifyIn(sut: sut, userValue: Int32.zero, matchValue: HackleValue(value: Double.zero), expected: true)
                verifyIn(sut: sut, userValue: Int64.zero, matchValue: HackleValue(value: Double.zero), expected: true)
            }
            
            it("matchValue가 숫자가 아니면 아니면 항상 false") {
                verifyIn(sut: sut, userValue: "1", matchValue: HackleValue(value: true), expected: false)
                verifyContains(sut: sut, userValue: "42", matchValue: HackleValue(value: false), expected: false)
                verifyStartsWith(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
                verifyEndsWith(sut: sut, userValue: "1", matchValue: HackleValue(value: false), expected: false)
                verifyGreaterThan(sut: sut, userValue: "42", matchValue: HackleValue(value: "string"), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: "42", matchValue: HackleValue(value: "1.1.1"), expected: false)
                verifyLessThan(sut: sut, userValue: "42", matchValue: HackleValue(value: "string"), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: "42", matchValue: HackleValue(value: tmp()), expected: false)
            }
            
            it("userValue가 숫자가 아니면 항상 false") {
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "1"), expected: false)
                verifyContains(sut: sut, userValue: "false", matchValue: HackleValue(value: "42"), expected: false)
                verifyStartsWith(sut: sut, userValue: "string", matchValue: HackleValue(value: "42"), expected: false)
                verifyEndsWith(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
                verifyGreaterThan(sut: sut, userValue: "1.1.1", matchValue: HackleValue(value: "42"), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: false, matchValue: HackleValue(value: "42"), expected: false)
                verifyLessThan(sut: sut, userValue: tmp(), matchValue: HackleValue(value: "42"), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: true, matchValue: HackleValue(value: "42"), expected: false)
            }

            it("string type 이면 캐스팅후 match") {
                verifyIn(sut: sut, userValue: "42", matchValue: HackleValue(value: "42"), expected: true)
                verifyIn(sut: sut, userValue: "42", matchValue: HackleValue(value: 42), expected: true)
                verifyIn(sut: sut, userValue: 42, matchValue: HackleValue(value: "42"), expected: true)

                verifyIn(sut: sut, userValue: "42.42", matchValue: HackleValue(value: "42.42"), expected: true)
                verifyIn(sut: sut, userValue: "42.42", matchValue: HackleValue(value: 42.42), expected: true)
                verifyIn(sut: sut, userValue: 42.42, matchValue: HackleValue(value: "42.42"), expected: true)
                
                verifyIn(sut: sut, userValue: "42.0", matchValue: HackleValue(value: "42.0"), expected: true)
                verifyIn(sut: sut, userValue: "42.0", matchValue: HackleValue(value: 42.0), expected: true)
                verifyIn(sut: sut, userValue: 42.0, matchValue: HackleValue(value: "42.0"), expected: true)
            }

            it("지원하지 않는 type") {
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: 1), expected: false)
                verifyIn(sut: sut, userValue: 1, matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: "42a", matchValue: HackleValue(value: 42), expected: false)
            }
            
            it("지원하지 않는 연산자") {
                verifyContains(sut: sut, userValue: 42, matchValue: HackleValue(value: 42), expected: false)
                verifyStartsWith(sut: sut, userValue: 42, matchValue: HackleValue(value: 42), expected: false)
                verifyEndsWith(sut: sut, userValue: 42, matchValue: HackleValue(value: 42), expected: false)
            }
        }

        describe("BoolMatcher") {
            let sut = BoolMatcher()

            it("bool type") {
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: true)
                verifyIn(sut: sut, userValue: "true", matchValue: HackleValue(value: true), expected: true)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "true"), expected: true)
                verifyIn(sut: sut, userValue: "true", matchValue: HackleValue(value: "true"), expected: true)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: false), expected: true)
                verifyIn(sut: sut, userValue: "false", matchValue: HackleValue(value: false), expected: true)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: "false"), expected: true)
                verifyIn(sut: sut, userValue: "false", matchValue: HackleValue(value: "false"), expected: true)
                
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: false), expected: false)
                verifyIn(sut: sut, userValue: "true", matchValue: HackleValue(value: false), expected: false)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: "false", matchValue: HackleValue(value: true), expected: false)
                
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: 1), expected: false)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "1"), expected: false)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: 0), expected: false)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: "0"), expected: false)
                verifyIn(sut: sut, userValue: 1, matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: "1", matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: 0, matchValue: HackleValue(value: false), expected: false)
                verifyIn(sut: sut, userValue: "0", matchValue: HackleValue(value: false), expected: false)
                
                verifyIn(sut: sut, userValue: "0", matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: 0, matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: "1", matchValue: HackleValue(value: false), expected: false)
                verifyIn(sut: sut, userValue: 1, matchValue: HackleValue(value: false), expected: false)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "0"), expected: false)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: 0), expected: false)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: "1"), expected: false)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: 1), expected: false)
                
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "TRUE"), expected: false)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: "FALSE"), expected: false)
                verifyIn(sut: sut, userValue: "TRUE", matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: "FALSE", matchValue: HackleValue(value: false), expected: false)
            }
            
            it("matchValue가 Bool이 아니면 항상 false") {
                verifyIn(sut: sut, userValue: "true", matchValue: HackleValue(value: tmp()), expected: false)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "string"), expected: false)
                verifyIn(sut: sut, userValue: "false", matchValue: HackleValue(value: "1.1.1"), expected: false)
                verifyIn(sut: sut, userValue: false, matchValue: HackleValue(value: 234), expected: false)
            }

            it("userValue가 Bool타입이 아니면 false") {
                verifyIn(sut: sut, userValue: "string", matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: 234, matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: tmp(), matchValue: HackleValue(value: true), expected: false)
                verifyIn(sut: sut, userValue: "1.1.1", matchValue: HackleValue(value: true), expected: false)
            }

            it("지원하지 않는 연산자") {
                verifyContains(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: false)
                verifyStartsWith(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: false)
                verifyEndsWith(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: false)
                verifyGreaterThan(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: false)
                verifyLessThan(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: false)
            }
        }

        describe("VersionMatcher") {
            let sut = VersionMatcher()
            
            it("version type") {
                verifyIn(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.0"), expected: true)
                verifyIn(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "2.0.0"), expected: false)
                verifyGreaterThan(sut: sut, userValue: "1.0.1", matchValue: HackleValue(value: "1.0.0"), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.0"), expected: true)
                verifyGreaterThanOrEqual(sut: sut, userValue: "1.0.1", matchValue: HackleValue(value: "1.0.0"), expected: true)
                verifyLessThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.1"), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.0"), expected: true)
                verifyLessThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.1"), expected: true)
            }

            it("matchValue가 Version 타입이 아니면 항상 false") {
                verifyIn(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: Int.max), expected: false)
                verifyIn(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: 1.0), expected: false)
                verifyIn(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.asd"), expected: false)
                verifyIn(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "string"), expected: false)
                verifyIn(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: true), expected: false)
                
                verifyGreaterThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: Int.max), expected: false)
                verifyGreaterThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: 1.0), expected: false)
                verifyGreaterThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.asd"), expected: false)
                verifyGreaterThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "string"), expected: false)
                verifyGreaterThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: true), expected: false)
                
                verifyGreaterThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: Int.max), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: 1.0), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.asd"), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "string"), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: true), expected: false)
                
                verifyLessThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: Int.max), expected: false)
                verifyLessThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: 1.0), expected: false)
                verifyLessThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0"), expected: false)
                verifyLessThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "string"), expected: false)
                verifyLessThan(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: true), expected: false)
                
                verifyLessThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: Int.max), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: 1.0), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.asd"), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "string"), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: true), expected: false)
            }

            it("userValue가 Version 타입이 아니면 false") {
                verifyIn(sut: sut, userValue: Int.max, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyIn(sut: sut, userValue: 1.0, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyIn(sut: sut, userValue: "1.0.x", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyIn(sut: sut, userValue: "string", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyIn(sut: sut, userValue: true, matchValue: HackleValue(value: "1.0.0"), expected: false)
                
                verifyGreaterThan(sut: sut, userValue: Int.max, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyGreaterThan(sut: sut, userValue: 1.0, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyGreaterThan(sut: sut, userValue: "1.0", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyGreaterThan(sut: sut, userValue: "string", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyGreaterThan(sut: sut, userValue: true, matchValue: HackleValue(value: "1.0.0"), expected: false)
                
                verifyGreaterThanOrEqual(sut: sut, userValue: Int.max, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: 1.0, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: "1.0.x", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: "string", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyGreaterThanOrEqual(sut: sut, userValue: true, matchValue: HackleValue(value: "1.0.0"), expected: false)
                
                verifyLessThan(sut: sut, userValue: Int.max, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyLessThan(sut: sut, userValue: 1.0, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyLessThan(sut: sut, userValue: "1.0", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyLessThan(sut: sut, userValue: "string", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyLessThan(sut: sut, userValue: true, matchValue: HackleValue(value: "1.0.0"), expected: false)
                
                verifyLessThanOrEqual(sut: sut, userValue: Int.max, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: 1.0, matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: "1.0.x", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: "string", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyLessThanOrEqual(sut: sut, userValue: true, matchValue: HackleValue(value: "1.0.0"), expected: false)
            }

            it("지원하지 않는 연산자") {
                verifyContains(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyStartsWith(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.0"), expected: false)
                verifyEndsWith(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.0"), expected: false)
            }
        }
    }
    
    class tmp {
        let data: Any?
        
        init(data: Any? = nil) {
            self.data = data
        }
    }
    
    private static func v(_ value: Any) -> Any {
        if value is tmp {
            return value
        }
        
        let tmp = ["tmp": value]
        let data = Json.serialize(tmp)!
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        return dict["tmp"]!
    }

    private static func verifyIn(sut: ValueMatcher, userValue: Any, matchValue: HackleValue, expected: Bool) {
        let userValueList = [userValue, v(userValue), HackleValue(value: userValue)]
        let hackleValueWrapedMatchValue = HackleValue(value: matchValue)
        
        for user in userValueList {
            let case1 = sut.inMatch(userValue: user, matchValue: matchValue)
            let case2 = sut.inMatch(userValue: user, matchValue: hackleValueWrapedMatchValue)
            
            expect(case1).to(equal(expected))
            expect(case2).to(equal(expected))
        }
    }
    
    private static func verifyContains(sut: ValueMatcher, userValue: Any, matchValue: HackleValue, expected: Bool) {
        let userValueList = [userValue, v(userValue), HackleValue(value: userValue)]
        let hackleValueWrapedMatchValue = HackleValue(value: matchValue)
        
        for user in userValueList {
            let case1 = sut.containsMatch(userValue: user, matchValue: matchValue)
            let case2 = sut.containsMatch(userValue: user, matchValue: hackleValueWrapedMatchValue)
            
            expect(case1).to(equal(expected))
            expect(case2).to(equal(expected))
        }
    }
    
    private static func verifyStartsWith(sut: ValueMatcher, userValue: Any, matchValue: HackleValue, expected: Bool) {
        let userValueList = [userValue, v(userValue), HackleValue(value: userValue)]
        let hackleValueWrapedMatchValue = HackleValue(value: matchValue)
        
        for user in userValueList {
            let case1 = sut.startsWithMatch(userValue: user, matchValue: matchValue)
            let case2 = sut.startsWithMatch(userValue: user, matchValue: hackleValueWrapedMatchValue)
            
            expect(case1).to(equal(expected))
            expect(case2).to(equal(expected))
        }
    }
    
    private static func verifyEndsWith(sut: ValueMatcher, userValue: Any, matchValue: HackleValue, expected: Bool) {
        let userValueList = [userValue, v(userValue), HackleValue(value: userValue)]
        let hackleValueWrapedMatchValue = HackleValue(value: matchValue)
        
        for user in userValueList {
            let case1 = sut.endsWithMatch(userValue: user, matchValue: matchValue)
            let case2 = sut.endsWithMatch(userValue: user, matchValue: hackleValueWrapedMatchValue)
            
            expect(case1).to(equal(expected))
            expect(case2).to(equal(expected))
        }
        
    }
    
    private static func verifyGreaterThan(sut: ValueMatcher, userValue: Any, matchValue: HackleValue, expected: Bool) {
        let userValueList = [userValue, v(userValue), HackleValue(value: userValue)]
        let hackleValueWrapedMatchValue = HackleValue(value: matchValue)
        
        for user in userValueList {
            let case1 = sut.greaterThanMatch(userValue: user, matchValue: matchValue)
            let case2 = sut.greaterThanMatch(userValue: user, matchValue: hackleValueWrapedMatchValue)
            
            expect(case1).to(equal(expected))
            expect(case2).to(equal(expected))
        }
    }
    
    private static func verifyGreaterThanOrEqual(sut: ValueMatcher, userValue: Any, matchValue: HackleValue, expected: Bool) {
        let userValueList = [userValue, v(userValue), HackleValue(value: userValue)]
        let hackleValueWrapedMatchValue = HackleValue(value: matchValue)
        
        for user in userValueList {
            let case1 = sut.greaterThanOrEqualMatch(userValue: user, matchValue: matchValue)
            let case2 = sut.greaterThanOrEqualMatch(userValue: user, matchValue: hackleValueWrapedMatchValue)
            
            expect(case1).to(equal(expected))
            expect(case2).to(equal(expected))
        }
    }
    
    private static func verifyLessThan(sut: ValueMatcher, userValue: Any, matchValue: HackleValue, expected: Bool) {
        let userValueList = [userValue, v(userValue), HackleValue(value: userValue)]
        let hackleValueWrapedMatchValue = HackleValue(value: matchValue)
        
        for user in userValueList {
            let case1 = sut.lessThanMatch(userValue: user, matchValue: matchValue)
            let case2 = sut.lessThanMatch(userValue: user, matchValue: hackleValueWrapedMatchValue)
            
            expect(case1).to(equal(expected))
            expect(case2).to(equal(expected))
        }
    }
    
    private static func verifyLessThanOrEqual(sut: ValueMatcher, userValue: Any, matchValue: HackleValue, expected: Bool) {
        let userValueList = [userValue, v(userValue), HackleValue(value: userValue)]
        let hackleValueWrapedMatchValue = HackleValue(value: matchValue)
        
        for user in userValueList {
            let case1 = sut.lessThanOrEqualMatch(userValue: user, matchValue: matchValue)
            let case2 = sut.lessThanOrEqualMatch(userValue: user, matchValue: hackleValueWrapedMatchValue)
            
            expect(case1).to(equal(expected))
            expect(case2).to(equal(expected))
        }
    }
}

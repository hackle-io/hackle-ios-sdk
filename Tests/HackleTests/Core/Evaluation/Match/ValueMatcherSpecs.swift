import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class ValueMatcherSpecs: QuickSpec {
    override func spec() {

        describe("StringMatcher") {
            let sut = StringMatcher()

            it("string type match") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "42", matchValue: HackleValue(value: "42"))).to(beTrue())
            }

            it("number 타입이면 캐스팅 후 match") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "42", matchValue: HackleValue(value: 42))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42, matchValue: HackleValue(value: "42"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42, matchValue: HackleValue(value: 42))).to(beTrue())
            }

            it("지원하지 않는 type") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: true))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: "1"))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1", matchValue: HackleValue(value: true))).to(beFalse())
            }
        }

        describe("NumberMatcher") {

            let sut = NumberMatcher()

            it("number type") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42, matchValue: HackleValue(value: 42))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42.1, matchValue: HackleValue(value: 42.1))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42.0, matchValue: HackleValue(value: 42))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42, matchValue: HackleValue(value: 42.0))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 0, matchValue: HackleValue(value: 0.0))).to(beTrue())
            }

            it("string type 이면 캐스팅후 match") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "42", matchValue: HackleValue(value: "42"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "42", matchValue: HackleValue(value: 42))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42, matchValue: HackleValue(value: "42"))).to(beTrue())

                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "42.42", matchValue: HackleValue(value: "42.42"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "42.42", matchValue: HackleValue(value: 42.42))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42.42, matchValue: HackleValue(value: "42.42"))).to(beTrue())
            }

            it("지원하지 않는 type") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: true))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: 1))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: HackleValue(value: true))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "42a", matchValue: HackleValue(value: 42))).to(beFalse())
            }
        }

        describe("BoolMatcher") {

            let sut = BoolMatcher()

            it("userValue, matchValue가 Bool 타입이면 OperatorMatcher의 일치 결과로 평가한다") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: true))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: false, matchValue: HackleValue(value: false))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: false))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: false, matchValue: HackleValue(value: true))).to(beFalse())
            }

            it("userValue가 Bool타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "string", matchValue: HackleValue(value: true))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: HackleValue(value: true))).to(beFalse())
            }

            it("userValue가 Bool타입이지만 matchValue가 Bool타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: 1))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: "string"))).to(beFalse())
            }
            
            it("userValue 혹은 matchValue가 String타입이지만 true이거나 false이면 BoolMatcher의 일치 결과로 평가한다.") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "true", matchValue: HackleValue(value: true))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "TRUE", matchValue: HackleValue(value: true))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "false", matchValue: HackleValue(value: false))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "FALSE", matchValue: HackleValue(value: false))).to(beTrue())
                
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: "TRUE"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: "true"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: false, matchValue: HackleValue(value: "FALSE"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: false, matchValue: HackleValue(value: "false"))).to(beTrue())
                
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "FALSE", matchValue: HackleValue(value: true))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "true", matchValue: HackleValue(value: false))).to(beFalse())
            }
        }

        describe("VersionMatcher") {

            let sut = VersionMatcher()

            it("userValue, matchValue가 Version 타입이면 OperatorMatcher의 일치 결과로 평가한다") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1.0.0", matchValue: HackleValue(value: "1.0.0"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1.0.0", matchValue: HackleValue(value: "2.0.0"))).to(beFalse())
            }

            it("userValue가 Version 타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1.0, matchValue: HackleValue(value: "1.0.0"))).to(beFalse())
            }

            it("userValue가 Version 타입이지만 matchValue가 Version 타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1.0.0", matchValue: HackleValue(value: 1.0))).to(beFalse())
            }

            func v(_ version: String) -> Version {
                Version.tryParse(value: version)!
            }
        }
    }
}

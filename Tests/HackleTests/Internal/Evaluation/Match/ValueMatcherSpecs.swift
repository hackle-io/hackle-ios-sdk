import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class ValueMatcherSpecs: QuickSpec {
    override func spec() {

        describe("StringMatcher") {
            let sut = StringMatcher()

            it("userValue, matchValue가 String타입이면 OperatorMatcher의 일치 결과로 평가한다") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "value1", matchValue: HackleValue(value: "value1"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1", matchValue: HackleValue(value: "1"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "11", matchValue: HackleValue(value: "1"))).to(beFalse())
            }

            it("userValue가 String타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: HackleValue(value: "1"))).to(beFalse())
            }

            it("userValue가 String타입이지만 matchValue가 String타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1", matchValue: HackleValue(value: 1))).to(beFalse())
            }
        }

        describe("NumberMatcher") {

            let sut = NumberMatcher()

            it("userValue, matchValue가 Number타입이면 OperatorMatcher의 일치 결과로 평가한다") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42, matchValue: HackleValue(value: 42))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42.1, matchValue: HackleValue(value: 42.1))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42.0, matchValue: HackleValue(value: 42))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42, matchValue: HackleValue(value: 42.0))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 0, matchValue: HackleValue(value: 0.0))).to(beTrue())
            }

            it("userValue가 Number타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1", matchValue: HackleValue(value: 1))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: 1))).to(beFalse())
            }

            it("userValue가 Number타입이지만 matchValue가 Number타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: HackleValue(value: "1"))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: HackleValue(value: true))).to(beFalse())
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
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "true", matchValue: HackleValue(value: true))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: HackleValue(value: true))).to(beFalse())
            }

            it("userValue가 Bool타입이지만 matchValue가 Bool타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: 1))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: HackleValue(value: "true"))).to(beFalse())
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
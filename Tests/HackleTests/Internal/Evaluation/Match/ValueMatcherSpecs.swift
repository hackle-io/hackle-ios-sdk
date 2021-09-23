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
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "value1", matchValue: MatchValue(value: "value1"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1", matchValue: MatchValue(value: "1"))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "11", matchValue: MatchValue(value: "1"))).to(beFalse())
            }

            it("userValue가 String타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: MatchValue(value: "1"))).to(beFalse())
            }

            it("userValue가 String타입이지만 matchValue가 String타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1", matchValue: MatchValue(value: 1))).to(beFalse())
            }
        }

        describe("NumberMatcher") {

            let sut = NumberMatcher()

            it("userValue, matchValue가 Number타입이면 OperatorMatcher의 일치 결과로 평가한다") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42, matchValue: MatchValue(value: 42))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42.1, matchValue: MatchValue(value: 42.1))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42.0, matchValue: MatchValue(value: 42))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 42, matchValue: MatchValue(value: 42.0))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 0, matchValue: MatchValue(value: 0.0))).to(beTrue())
            }

            it("userValue가 Number타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "1", matchValue: MatchValue(value: 1))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: MatchValue(value: 1))).to(beFalse())
            }

            it("userValue가 Number타입이지만 matchValue가 Number타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: MatchValue(value: "1"))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: MatchValue(value: true))).to(beFalse())
            }
        }

        describe("BoolMatcher") {

            let sut = BoolMatcher()

            it("userValue, matchValue가 Bool 타입이면 OperatorMatcher의 일치 결과로 평가한다") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: MatchValue(value: true))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: false, matchValue: MatchValue(value: false))).to(beTrue())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: MatchValue(value: false))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: false, matchValue: MatchValue(value: true))).to(beFalse())
            }

            it("userValue가 Bool타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: "true", matchValue: MatchValue(value: true))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: 1, matchValue: MatchValue(value: true))).to(beFalse())
            }

            it("userValue가 Bool타입이지만 matchValue가 Bool타입이 아니면 false") {
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: MatchValue(value: 1))).to(beFalse())
                expect(sut.matches(operatorMatcher: InMatcher(), userValue: true, matchValue: MatchValue(value: "true"))).to(beFalse())
            }
        }
    }
}
import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class ValueMatcherSpecs: QuickSpec {

    private func v(_ value: Any) -> Any {
        let tmp = ["tmp": value]
        let data = Json.serialize(tmp)!
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        return dict["tmp"]!
    }

    private func verify(sut: ValueMatcher, userValue: Any, matchValue: HackleValue, expected: Bool) {
        let matcher = InMatcher()
        let v1 = userValue
        let a1 = sut.matches(operatorMatcher: matcher, userValue: v1, matchValue: matchValue)
        expect(a1).to(equal(expected))

        let v2 = v(userValue)
        let a2 = sut.matches(operatorMatcher: matcher, userValue: v2, matchValue: matchValue)
        expect(a2).to(equal(expected))
    }

    override func spec() {

        describe("StringMatcher") {
            let sut = StringMatcher()

            it("string type match") {
                self.verify(sut: sut, userValue: "42", matchValue: HackleValue(value: "42"), expected: true)
                self.verify(sut: sut, userValue: "42", matchValue: HackleValue(value: "42"), expected: true)
            }

            it("number 타입이면 캐스팅 후 match") {
                self.verify(sut: sut, userValue: "42", matchValue: HackleValue(value: 42), expected: true)
                self.verify(sut: sut, userValue: 42, matchValue: HackleValue(value: "42"), expected: true)
                self.verify(sut: sut, userValue: 42, matchValue: HackleValue(value: 42), expected: true)
            }

            it("bool 타입이면 캐스팅 후 match") {
                self.verify(sut: sut, userValue: "true", matchValue: HackleValue(value: true), expected: true)
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: "true"), expected: true)
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: true)
                self.verify(sut: sut, userValue: "false", matchValue: HackleValue(value: false), expected: true)
                self.verify(sut: sut, userValue: false, matchValue: HackleValue(value: "false"), expected: true)
                self.verify(sut: sut, userValue: false, matchValue: HackleValue(value: false), expected: true)

                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: "TRUE"), expected: false)
                self.verify(sut: sut, userValue: false, matchValue: HackleValue(value: "FALSE"), expected: false)
            }

            it("지원하지 않는 type") {
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: "1"), expected: false)
                self.verify(sut: sut, userValue: "1", matchValue: HackleValue(value: true), expected: false)
            }
        }

        describe("NumberMatcher") {

            let sut = NumberMatcher()

            it("number type") {
                self.verify(sut: sut, userValue: 42, matchValue: HackleValue(value: 42), expected: true)
                self.verify(sut: sut, userValue: 42.1, matchValue: HackleValue(value: 42.1), expected: true)
                self.verify(sut: sut, userValue: 42.0, matchValue: HackleValue(value: 42), expected: true)
                self.verify(sut: sut, userValue: 42, matchValue: HackleValue(value: 42.0), expected: true)
                self.verify(sut: sut, userValue: 0, matchValue: HackleValue(value: 0.0), expected: true)
            }

            it("string type 이면 캐스팅후 match") {
                self.verify(sut: sut, userValue: "42", matchValue: HackleValue(value: "42"), expected: true)
                self.verify(sut: sut, userValue: "42", matchValue: HackleValue(value: 42), expected: true)
                self.verify(sut: sut, userValue: 42, matchValue: HackleValue(value: "42"), expected: true)

                self.verify(sut: sut, userValue: "42.42", matchValue: HackleValue(value: "42.42"), expected: true)
                self.verify(sut: sut, userValue: "42.42", matchValue: HackleValue(value: 42.42), expected: true)
                self.verify(sut: sut, userValue: 42.42, matchValue: HackleValue(value: "42.42"), expected: true)
            }

            it("지원하지 않는 type") {
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: false)
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: 1), expected: false)
                self.verify(sut: sut, userValue: 1, matchValue: HackleValue(value: true), expected: false)
                self.verify(sut: sut, userValue: "42a", matchValue: HackleValue(value: 42), expected: false)
            }
        }

        describe("BoolMatcher") {

            let sut = BoolMatcher()

            it("userValue, matchValue가 Bool 타입이면 OperatorMatcher의 일치 결과로 평가한다") {
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: true), expected: true)
                self.verify(sut: sut, userValue: false, matchValue: HackleValue(value: false), expected: true)
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: false), expected: false)
                self.verify(sut: sut, userValue: false, matchValue: HackleValue(value: true), expected: false)
            }

            it("userValue가 Bool타입이 아니면 false") {
                self.verify(sut: sut, userValue: "string", matchValue: HackleValue(value: true), expected: false)
                self.verify(sut: sut, userValue: 1, matchValue: HackleValue(value: true), expected: false)
            }

            it("userValue가 Bool타입이지만 matchValue가 Bool타입이 아니면 false") {
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: 1), expected: false)
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: "string"), expected: false)
            }

            it("userValue 혹은 matchValue가 String타입이지만 true이거나 false이면 BoolMatcher의 일치 결과로 평가한다.") {
                self.verify(sut: sut, userValue: "true", matchValue: HackleValue(value: true), expected: true)
                self.verify(sut: sut, userValue: "false", matchValue: HackleValue(value: false), expected: true)
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: "true"), expected: true)
                self.verify(sut: sut, userValue: false, matchValue: HackleValue(value: "false"), expected: true)

                self.verify(sut: sut, userValue: "TRUE", matchValue: HackleValue(value: true), expected: false)
                self.verify(sut: sut, userValue: "FALSE", matchValue: HackleValue(value: false), expected: false)
                self.verify(sut: sut, userValue: true, matchValue: HackleValue(value: "TRUE"), expected: false)
                self.verify(sut: sut, userValue: false, matchValue: HackleValue(value: "FALSE"), expected: false)
                self.verify(sut: sut, userValue: "FALSE", matchValue: HackleValue(value: true), expected: false)
                self.verify(sut: sut, userValue: "true", matchValue: HackleValue(value: false), expected: false)
            }
        }

        describe("VersionMatcher") {

            let sut = VersionMatcher()

            it("userValue, matchValue가 Version 타입이면 OperatorMatcher의 일치 결과로 평가한다") {
                self.verify(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "1.0.0"), expected: true)
                self.verify(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: "2.0.0"), expected: false)
            }

            it("userValue가 Version 타입이 아니면 false") {
                self.verify(sut: sut, userValue: 1.0, matchValue: HackleValue(value: "1.0.0"), expected: false)
            }

            it("userValue가 Version 타입이지만 matchValue가 Version 타입이 아니면 false") {
                self.verify(sut: sut, userValue: "1.0.0", matchValue: HackleValue(value: 1.0), expected: false)
            }

            func v(_ version: String) -> Version {
                Version.tryParse(value: version)!
            }
        }
    }
}

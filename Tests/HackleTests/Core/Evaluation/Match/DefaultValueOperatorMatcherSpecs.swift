import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultValueOperatorMatcherSpecs: QuickSpec {

    override func spec() {

        let sut = DefaultValueOperatorMatcher(valueMatcherFactory: ValueMatcherFactory(), operatorMatcherFactory: OperatorMatcherFactory())

        it("match Value 중 하나라도 일치하는 값이 있으면 true") {

            let match = Target.Match(
                type: .match,
                matchOperator: ._in,
                valueType: .number,
                values: [
                    HackleValue(value: 1),
                    HackleValue(value: 2),
                    HackleValue(value: 3)
                ])

            let actual = sut.matches(userValue: 3, match: match)

            expect(actual).to(beTrue())
        }

        it("match values중 일치하는 값이 하나도 없으면 false") {

            let match = Target.Match(
                type: .match,
                matchOperator: ._in,
                valueType: .number,
                values: [
                    HackleValue(value: 1),
                    HackleValue(value: 2),
                    HackleValue(value: 3)
                ])

            let actual = sut.matches(userValue: 4, match: match)

            expect(actual).to(beFalse())
        }

        it("일치하는 값이 있지만 MatchType이 NOT_MATCH면 false") {

            let match = Target.Match(
                type: .notMatch,
                matchOperator: ._in,
                valueType: .number,
                values: [
                    HackleValue(value: 1),
                    HackleValue(value: 2),
                    HackleValue(value: 3)
                ])

            let actual = sut.matches(userValue: 3, match: match)

            expect(actual).to(beFalse())
        }

        it("일치하는 값이 없지만 MatchType이 NOT_MATCH면 true") {

            let match = Target.Match(
                type: .notMatch,
                matchOperator: ._in,
                valueType: .number,
                values: [
                    HackleValue(value: 1),
                    HackleValue(value: 2),
                    HackleValue(value: 3)
                ])

            let actual = sut.matches(userValue: 4, match: match)

            expect(actual).to(beTrue())
        }

        it("userValue 가 array 인 경우 하나라도 매칭되면 true") {

            let match = Target.Match(
                type: .match,
                matchOperator: ._in,
                valueType: .number,
                values: [
                    HackleValue(value: 1),
                    HackleValue(value: 2),
                    HackleValue(value: 3)
                ])

            let actual = sut.matches(userValue: [-1, 0, 1], match: match)

            expect(actual).to(beTrue())
        }

        it("array userValue 중 매칭되는게 하나라도 없으면 false") {
            let match = Target.Match(
                type: .match,
                matchOperator: ._in,
                valueType: .number,
                values: [
                    HackleValue(value: 1),
                    HackleValue(value: 2),
                    HackleValue(value: 3)
                ])

            let actual = sut.matches(userValue: [4, 5, 6], match: match)

            expect(actual).to(beFalse())
        }

        it("empty array 인 경우 false") {
            let match = Target.Match(
                type: .match,
                matchOperator: ._in,
                valueType: .number,
                values: [
                    HackleValue(value: 1),
                    HackleValue(value: 2),
                    HackleValue(value: 3)
                ])

            let actual = sut.matches(userValue: [], match: match)

            expect(actual).to(beFalse())
        }

        it("matches") {

            func check(type: Target.MatchType, userValue: Any, matchValues: [String], expected: Bool) {
                let match = Target.Match(type: type, matchOperator: ._in, valueType: .string, values: matchValues.map({ .string($0) }))
                let actual = sut.matches(userValue: userValue, match: match)
                expect(actual) == expected
            }

            // A 는 [A] 중 하나
            check(type: .match, userValue: "A", matchValues: ["A"], expected: true)

            // A 는 [A, B] 중 하나
            check(type: .match, userValue: "A", matchValues: ["A", "B"], expected: true)

            // B 는 [A, B] 중 하나
            check(type: .match, userValue: "B", matchValues: ["A", "B"], expected: true)

            // A 는 [B] 중 하나
            check(type: .match, userValue: "A", matchValues: ["B"], expected: false)

            // A 는 [B, C] 중 하나
            check(type: .match, userValue: "A", matchValues: ["B", "C"], expected: false)

            // [] 는 [A] 중 하나
            check(type: .match, userValue: [], matchValues: ["A"], expected: false)

            // [A] 는 [A] 중 하나
            check(type: .match, userValue: ["A"], matchValues: ["A"], expected: true)

            // [A] 는 [A, B] 중 하나
            check(type: .match, userValue: ["A"], matchValues: ["A", "B"], expected: true)

            // [B] 는 [A, B] 중 하나
            check(type: .match, userValue: ["B"], matchValues: ["A", "B"], expected: true)

            // [A] 는 [B] 중 하나
            check(type: .match, userValue: ["A"], matchValues: ["B"], expected: false)

            // [A] 는 [B, C] 중 하나
            check(type: .match, userValue: ["A"], matchValues: ["B", "C"], expected: false)

            // [A, B] 는 [A] 중 하나
            check(type: .match, userValue: ["A", "B"], matchValues: ["A"], expected: true)

            // [A, B] 는 [B] 중 하나
            check(type: .match, userValue: ["A", "B"], matchValues: ["B"], expected: true)

            // [A, B] 는 [C] 중 하나
            check(type: .match, userValue: ["A", "B"], matchValues: ["C"], expected: false)

            // [A, B] 는 [A, B] 중 하나
            check(type: .match, userValue: ["A", "B"], matchValues: ["A", "B"], expected: true)

            // [A, B] 는 [A, C] 중 하나
            check(type: .match, userValue: ["A", "B"], matchValues: ["A", "C"], expected: true)

            // [A, B] 는 [B, C] 중 하나
            check(type: .match, userValue: ["A", "B"], matchValues: ["B", "C"], expected: true)

            // [A, B] 는 [A, C] 중 하나
            check(type: .match, userValue: ["A", "B"], matchValues: ["A", "C"], expected: true)

            // [A, B] 는 [C, A] 중 하나
            check(type: .match, userValue: ["A", "B"], matchValues: ["C", "A"], expected: true)

            // [A, B] 는 [C, D] 중 하나
            check(type: .match, userValue: ["A", "B"], matchValues: ["C", "D"], expected: false)

            // A 는 [A] 중 하나가 아닌
            check(type: .notMatch, userValue: "A", matchValues: ["A"], expected: false)

            // A 는 [A, B] 중 하나가 아닌
            check(type: .notMatch, userValue: "A", matchValues: ["A", "B"], expected: false)

            // B 는 [A, B] 중 하나가 아닌
            check(type: .notMatch, userValue: "B", matchValues: ["A", "B"], expected: false)

            // A 는 [B] 중 하나가 아닌
            check(type: .notMatch, userValue: "A", matchValues: ["B"], expected: true)

            // A 는 [B, C] 중 하나가 아닌
            check(type: .notMatch, userValue: "A", matchValues: ["B", "C"], expected: true)

            // [] 는 [A] 중 하나가 아닌
            check(type: .notMatch, userValue: [], matchValues: ["A"], expected: true)

            // [A] 는 [A] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A"], matchValues: ["A"], expected: false)

            // [A] 는 [A, B] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A"], matchValues: ["A", "B"], expected: false)

            // [B] 는 [A, B] 중 하나가 아닌
            check(type: .notMatch, userValue: ["B"], matchValues: ["A", "B"], expected: false)

            // [A] 는 [B] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A"], matchValues: ["B"], expected: true)

            // [A] 는 [B, C] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A"], matchValues: ["B", "C"], expected: true)

            // [A, B] 는 [A] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A", "B"], matchValues: ["A"], expected: false)

            // [A, B] 는 [B] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A", "B"], matchValues: ["B"], expected: false)

            // [A, B] 는 [C] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A", "B"], matchValues: ["C"], expected: true)

            // [A, B] 는 [A, B] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A", "B"], matchValues: ["A", "B"], expected: false)

            // [A, B] 는 [A, C] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A", "B"], matchValues: ["A", "C"], expected: false)

            // [A, B] 는 [B, C] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A", "B"], matchValues: ["B", "C"], expected: false)

            // [A, B] 는 [A, C] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A", "B"], matchValues: ["A", "C"], expected: false)

            // [A, B] 는 [C, A] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A", "B"], matchValues: ["C", "A"], expected: false)

            // [A, B] 는 [C, D] 중 하나가 아닌
            check(type: .notMatch, userValue: ["A", "B"], matchValues: ["C", "D"], expected: true)
        }
    }
}

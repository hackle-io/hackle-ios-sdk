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
    }
}
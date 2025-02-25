import Foundation
import Quick
import Nimble
@testable import Hackle


class SegmentConditionMatcherSpecs: QuickSpec {
    override func spec() {

        var segmentMatcher: MockSegmentMatcher!
        var sut: SegmentConditionMatcher!

        beforeEach {
            segmentMatcher = MockSegmentMatcher()
            sut = SegmentConditionMatcher(segmentMatcher: segmentMatcher)
        }

        it("keyType 이 segment 가 아니면 예외 발생") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .userProperty, name: "age"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [HackleValue(value: 42)])
            )

            // when
            let actual = expect(try sut.matches(request: experimentRequest(), context: Evaluators.context(), condition: condition))

            // then
            actual.to(throwError(HackleError.error("Unsupported TargetKeyType [userProperty]")))
        }

        it("등록된 segmentKey 가 String 타입이 아니면 예외가 발생한다") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .segment, name: "SEGMENT"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: 42)])
            )

            // when
            let actual = expect(try sut.matches(request: experimentRequest(), context: Evaluators.context(), condition: condition))

            // then
            actual.to(throwError(HackleError.error("SegmentKey[int(42)]")))
        }

        it("등록된 segmentKey 에 해당하는 Segment 가 없으면 예외가 발생한다") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .segment, name: "SEGMENT"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "seg1")])
            )

            let workspace = MockWorkspace()
            every(workspace.getSegmentOrNilMock).returns(nil)

            let request = experimentRequest(workspace: workspace)

            // when
            let actual = expect(try sut.matches(request: request, context: Evaluators.context(), condition: condition))

            // then
            actual.to(throwError(HackleError.error("Segment[seg1]")))
        }

        it("등록된 segment 중 일치하는게 하나라도 있으면 true") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .segment, name: "SEGMENT"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "seg1"), HackleValue(value: "seg2"), HackleValue(value: "seg3")])
            )
            let workspace = MockWorkspace()
            every(workspace.getSegmentOrNilMock).returns(MockSegment())

            every(segmentMatcher.matchesMock).returns(true)

            let request = experimentRequest(workspace: workspace)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual) == true
        }

        it("등록된 segment 중 일치하는게 하나도 없으면 false") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .segment, name: "SEGMENT"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "seg1"), HackleValue(value: "seg2"), HackleValue(value: "seg3")])
            )
            let workspace = MockWorkspace()
            every(workspace.getSegmentOrNilMock).returns(MockSegment())

            every(segmentMatcher.matchesMock).returns(false)

            let request = experimentRequest(workspace: workspace)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual) == false
        }

        it("등록된 segment 중 일치하는게 있지만 MatchType.NOT_MATCH 인 경우 false") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .segment, name: "SEGMENT"),
                match: Target.Match(type: .notMatch, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "seg1"), HackleValue(value: "seg2"), HackleValue(value: "seg3")])
            )
            let workspace = MockWorkspace()
            every(workspace.getSegmentOrNilMock).returns(MockSegment())

            every(segmentMatcher.matchesMock).returns(false)

            let request = experimentRequest(workspace: workspace)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual) == true
        }
    }
}

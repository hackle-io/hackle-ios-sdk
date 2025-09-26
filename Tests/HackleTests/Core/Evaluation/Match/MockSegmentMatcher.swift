import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class MockSegmentMatcher: Mock, SegmentMatcher {

    lazy var matchesMock = MockFunction(self, matches)

    func matches(request: EvaluatorRequest, context: EvaluatorContext, segment: Segment) throws -> Bool {
        call(matchesMock, args: (request, context, segment))
    }

}
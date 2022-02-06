import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockSegmentMatcher: Mock, SegmentMatcher {

    lazy var matchesMock = MockFunction(self, matches)

    func matches(segment: Segment, workspace: Workspace, user: HackleUser) throws -> Bool {
        return call(matchesMock, args: (segment, workspace, user))
    }
}
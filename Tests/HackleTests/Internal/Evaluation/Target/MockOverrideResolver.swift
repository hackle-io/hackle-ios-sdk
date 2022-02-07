import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockOverrideResolver: Mock, OverrideResolver {

    lazy var resolveOrNilMock = MockFunction(self, resolveOrNil)

    func resolveOrNil(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Variation? {
        call(resolveOrNilMock, args: (workspace, experiment, user))
    }
}
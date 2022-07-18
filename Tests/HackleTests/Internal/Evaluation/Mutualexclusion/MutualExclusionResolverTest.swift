import Foundation
import Mockery
@testable import Hackle

class MockMutualExclusionResolver: Mock, MutualExclusionResolver {

    lazy var resolverOrNilMock = MockFunction(self, isMutualExclusionGroup)

    func isMutualExclusionGroup(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Bool {
        call(resolverOrNilMock, args: (workspace, experiment, user))
    }
}

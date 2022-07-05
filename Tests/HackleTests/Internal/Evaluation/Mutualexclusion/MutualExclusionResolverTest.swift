import Foundation
import Mockery
@testable import Hackle

class MockMutualExclusionResolver: Mock, MutualExclusionResolver {

    lazy var resolverOrNilMock = MockFunction(self, resolve)

    func resolve(workspace: Workspace, experiment: Experiment, identifier: String) throws -> Bool {
        call(resolverOrNilMock, args: (workspace, experiment, identifier))
    }
}

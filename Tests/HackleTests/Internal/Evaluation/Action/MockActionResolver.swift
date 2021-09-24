import Foundation
import Mockery
@testable import Hackle

class MockActionResolver: Mock, ActionResolver {
    
    lazy var resolveOrNilMock = MockFunction(self, resolveOrNil)

    func resolveOrNil(action: Action, workspace: Workspace, experiment: Experiment, user: User) -> Variation? {
        call(resolveOrNilMock, args: (action, workspace, experiment, user))
    }
}

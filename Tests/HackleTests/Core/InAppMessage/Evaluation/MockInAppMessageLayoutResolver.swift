import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageLayoutResolver: Mock, InAppMessageLayoutResolver {
    lazy var resolveMock = MockFunction.throwable(self, resolve)

    func resolve(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser) throws -> InAppMessageLayoutEvaluation {
        return try call(resolveMock, args: (workspace, inAppMessage, user))
    }
}

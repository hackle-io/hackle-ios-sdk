import Foundation
import MockingKit
@testable import Hackle

class MockWorkspaceConfigFetcher: Mock, WorkspaceConfigFetcher {
    lazy var workspaceMock = MockFunction(self, workspace)

    func workspace(user: HackleUser) -> WorkspaceConfig? {
        call(workspaceMock, args: user)
    }
}

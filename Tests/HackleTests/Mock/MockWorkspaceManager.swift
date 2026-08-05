//
// Created by yong on 2020/12/11.
//

import Foundation

import Foundation
import MockingKit
@testable import Hackle

class MockWorkspaceManager: Mock, WorkspaceManager {

    lazy var initializeMock = MockFunction(self, initialize)

    func initialize() {
        call(initializeMock, args: ())
    }

    lazy var metadataMock = MockFunction(self, metadata)

    func metadata() -> WorkspaceMetadata? {
        call(metadataMock, args: ())
    }

    lazy var workspaceMock = MockFunction(self, workspace)

    func workspace(user: HackleUser) -> Workspace? {
        call(workspaceMock, args: user)
    }
}

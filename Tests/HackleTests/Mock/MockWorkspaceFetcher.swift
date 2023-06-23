//
// Created by yong on 2020/12/11.
//

import Foundation

import Foundation
import Mockery
@testable import Hackle

class MockWorkspaceFetcher: Mock, WorkspaceFetcher {

    lazy var getWorkspaceOrNilMock = MockFunction(self, fetch)

    func fetch() -> Workspace? {
        call(getWorkspaceOrNilMock, args: ())
    }
    
    lazy var initializeMock = MockFunction(self, initialize)

    func initialize(completion: @escaping () -> ()) {
        call(initializeMock, args: completion)
    }
}

//
// Created by yong on 2020/12/11.
//

import Foundation

import Foundation
import Mockery
@testable import Hackle

class MockWorkspaceFetcher: Mock, WorkspaceFetcher {

    lazy var getWorkspaceOrNilMock = MockFunction(self, getWorkspaceOrNil)

    func getWorkspaceOrNil() -> Workspace? {
        call(getWorkspaceOrNilMock, args: ())
    }

    lazy var fetchFromServerMock = MockFunction(self, fetchFromServer)

    func fetchFromServer(completion: @escaping () -> ()) {
        call(fetchFromServerMock, args: completion)
    }
}

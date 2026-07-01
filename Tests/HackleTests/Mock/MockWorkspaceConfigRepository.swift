import Foundation
@testable import Hackle

class MockWorkspaceConfigRepository: WorkspaceConfigRepository {
    var value: WorkspaceConfigResponse?

    init(value: WorkspaceConfigResponse? = nil) {
        self.value = value
    }

    func get() -> WorkspaceConfigResponse? {
        return self.value
    }

    func set(value: WorkspaceConfigResponse) {
        self.value = value
    }
}

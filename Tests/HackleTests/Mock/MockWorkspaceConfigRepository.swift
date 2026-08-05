import Foundation
@testable import Hackle

class MockWorkspaceConfigRepository: WorkspaceConfigRepository {
    var value: WorkspaceConfigContext?

    init(value: WorkspaceConfigContext? = nil) {
        self.value = value
    }

    func get() -> WorkspaceConfigContext? {
        return self.value
    }

    func set(value: WorkspaceConfigContext) {
        self.value = value
    }
}

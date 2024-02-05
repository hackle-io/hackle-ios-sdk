import Foundation
@testable import Hackle

class MockWorkspaceConfigRepository: WorkspaceConfigRepository {
    var value: WorkspaceConfig?
    
    init(value: WorkspaceConfig? = nil) {
        self.value = value
    }
    
    func get() -> WorkspaceConfig? {
        return self.value
    }
    
    func set(value: WorkspaceConfig) {
        self.value = value
    }
}

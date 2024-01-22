import Foundation

protocol WorkspaceConfigRepository {
    func get() -> WorkspaceConfig?
    func set(value: WorkspaceConfig)
}

class DefaultWorkspaceConfigRepository: WorkspaceConfigRepository {
    private let file: FileReadWriter?
    
    init(file: FileReadWriter?) {
        self.file = file
    }
    
    func get() -> WorkspaceConfig? {
        if let data = try? file?.read(),
           let config = try? JSONDecoder().decode(WorkspaceConfig.self, from: data) {
            return config
        } else {
            try? file?.delete()
            return nil
        }
    }
    
    func set(value: WorkspaceConfig) {
        if let data = try? JSONEncoder().encode(value) {
            try? file?.write(data: data)
        }
    }
}

fileprivate extension DefaultWorkspaceConfigRepository {
    private static let FILE_NAME = "workspace.json"
}

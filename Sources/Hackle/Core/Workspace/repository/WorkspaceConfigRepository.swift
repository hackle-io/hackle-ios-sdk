import Foundation

protocol WorkspaceConfigRepository {
    func get() -> WorkspaceConfig?
    func set(value: WorkspaceConfig)
}

class DefaultWorkspaceConfigRepository: WorkspaceConfigRepository {
    private let fileStorage: FileStorage?
    
    init(fileStorage: FileStorage?) {
        self.fileStorage = fileStorage
    }
    
    func get() -> WorkspaceConfig? {
        if let data = try? fileStorage?.read(filename: DefaultWorkspaceConfigRepository.FILE_NAME),
           let config = try? JSONDecoder().decode(WorkspaceConfig.self, from: data) {
            return config
        } else {
            try? fileStorage?.delete(filename: DefaultWorkspaceConfigRepository.FILE_NAME)
            return nil
        }
    }
    
    func set(value: WorkspaceConfig) {
        if let data = try? JSONEncoder().encode(value) {
            try? fileStorage?.write(filename: DefaultWorkspaceConfigRepository.FILE_NAME, data: data)
        }
    }
}

fileprivate extension DefaultWorkspaceConfigRepository {
    private static let FILE_NAME = "workspace.json"
}

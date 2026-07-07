import Foundation

protocol WorkspaceConfigRepository {
    func get() -> WorkspaceConfigResponse?
    func set(value: WorkspaceConfigResponse)
}

class DefaultWorkspaceConfigRepository: WorkspaceConfigRepository {
    private let fileStorage: FileStorage?
    
    init(fileStorage: FileStorage?) {
        self.fileStorage = fileStorage
    }
    
    func get() -> WorkspaceConfigResponse? {
        if let data = try? fileStorage?.read(filename: DefaultWorkspaceConfigRepository.FILE_NAME),
           let config = try? JSONDecoder().decode(WorkspaceConfigResponse.self, from: data) {
            return config
        } else {
            try? fileStorage?.delete(filename: DefaultWorkspaceConfigRepository.FILE_NAME)
            return nil
        }
    }
    
    func set(value: WorkspaceConfigResponse) {
        if let data = try? JSONEncoder().encode(value) {
            try? fileStorage?.write(filename: DefaultWorkspaceConfigRepository.FILE_NAME, data: data)
        }
    }
}

fileprivate extension DefaultWorkspaceConfigRepository {
    private static let FILE_NAME = "workspace.json"
}

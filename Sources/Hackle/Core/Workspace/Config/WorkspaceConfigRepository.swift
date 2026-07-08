import Foundation

protocol WorkspaceConfigRepository {
    func get() -> WorkspaceConfigContext?
    func set(value: WorkspaceConfigContext)
}

class DefaultWorkspaceConfigRepository: WorkspaceConfigRepository {
    private let fileStorage: FileStorage?

    init(fileStorage: FileStorage?) {
        self.fileStorage = fileStorage
    }

    func get() -> WorkspaceConfigContext? {
        if let data = try? fileStorage?.read(filename: DefaultWorkspaceConfigRepository.FILE_NAME),
           let dto = try? JSONDecoder().decode(WorkspaceConfigRecordDto.self, from: data) {
            return WorkspaceConfigContext.from(dto: dto)
        } else {
            try? fileStorage?.delete(filename: DefaultWorkspaceConfigRepository.FILE_NAME)
            return nil
        }
    }

    func set(value: WorkspaceConfigContext) {
        let dto = WorkspaceConfigRecordDto(lastModified: value.modifiedAt, config: value.dto)
        if let data = try? JSONEncoder().encode(dto) {
            try? fileStorage?.write(filename: DefaultWorkspaceConfigRepository.FILE_NAME, data: data)
        }
    }
}

fileprivate extension DefaultWorkspaceConfigRepository {
    private static let FILE_NAME = "workspace.json"
}

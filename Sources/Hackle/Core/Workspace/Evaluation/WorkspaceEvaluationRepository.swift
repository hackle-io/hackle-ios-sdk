import Foundation

protocol WorkspaceEvaluationRepository {
    func get() -> [WorkspaceEvaluationContext]
    func set(records: [WorkspaceEvaluationContext])
}

class FileWorkspaceEvaluationRepository: WorkspaceEvaluationRepository {

    private static let FILE_NAME = "workspace_evaluation.json"

    private let fileStorage: FileStorage?

    init(fileStorage: FileStorage?) {
        self.fileStorage = fileStorage
    }

    func get() -> [WorkspaceEvaluationContext] {
        guard let fileStorage = fileStorage, fileStorage.exists(filename: FileWorkspaceEvaluationRepository.FILE_NAME) else {
            return []
        }
        do {
            let data = try fileStorage.read(filename: FileWorkspaceEvaluationRepository.FILE_NAME)
            let contexts = try JSONDecoder().decode([WorkspaceEvaluationContextDto].self, from: data)
            return contexts.map { it in
                WorkspaceEvaluationContext.from(dto: it)
            }
        } catch {
            Log.error("Failed to read WorkspaceEvaluationContext: \(error)")
            try? fileStorage.delete(filename: FileWorkspaceEvaluationRepository.FILE_NAME)
            return []
        }
    }

    func set(records: [WorkspaceEvaluationContext]) {
        guard let fileStorage = fileStorage else {
            return
        }
        do {
            let dtos = records.map { it in
                WorkspaceEvaluationContextDto(key: it.key.identifiers, evaluation: it.dto, fullEvaluatedAt: it.fullEvaluatedAt)
            }
            let data = try JSONEncoder().encode(dtos)
            try fileStorage.write(filename: FileWorkspaceEvaluationRepository.FILE_NAME, data: data)
        } catch {
            Log.error("Failed to save WorkspaceEvaluationContext: \(error)")
        }
    }
}

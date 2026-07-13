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
            let records = try JSONDecoder().decode([WorkspaceEvaluationRecordDto].self, from: data)
            return records.map { it in
                WorkspaceEvaluationContext.from(dto: it)
            }
        } catch {
            Log.error("Failed to read WorkspaceEvaluationRecord: \(error)")
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
                WorkspaceEvaluationRecordDto(key: it.key.identifiers, evaluation: it.dto)
            }
            let data = try JSONEncoder().encode(dtos)
            try fileStorage.write(filename: FileWorkspaceEvaluationRepository.FILE_NAME, data: data)
        } catch {
            Log.error("Failed to save WorkspaceEvaluationRecord: \(error)")
        }
    }
}

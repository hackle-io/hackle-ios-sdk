import Foundation

class WorkspaceEvaluateResponse {

    let status: WorkspaceEvaluateStatus
    let evaluation: WorkspaceEvaluationDto?

    private init(status: WorkspaceEvaluateStatus, evaluation: WorkspaceEvaluationDto?) {
        self.status = status
        self.evaluation = evaluation
    }

    static func notModified() -> WorkspaceEvaluateResponse {
        WorkspaceEvaluateResponse(status: .notModified, evaluation: nil)
    }

    static func of(status: WorkspaceEvaluateStatus, dto: WorkspaceEvaluationDto) -> WorkspaceEvaluateResponse {
        WorkspaceEvaluateResponse(status: status, evaluation: dto)
    }
}

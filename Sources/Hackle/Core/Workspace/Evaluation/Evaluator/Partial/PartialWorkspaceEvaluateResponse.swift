import Foundation

class PartialWorkspaceEvaluateResponse: WorkspaceEvaluateResponse {

    let evaluation: WorkspaceEvaluation

    init(evaluation: WorkspaceEvaluation) {
        self.evaluation = evaluation
    }
}

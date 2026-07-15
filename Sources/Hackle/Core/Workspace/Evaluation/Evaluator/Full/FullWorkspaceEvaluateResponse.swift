import Foundation

class FullWorkspaceEvaluateResponse: WorkspaceEvaluateResponse {

    let context: WorkspaceEvaluationContext

    var evaluation: WorkspaceEvaluation {
        context.workspace
    }

    init(context: WorkspaceEvaluationContext) {
        self.context = context
    }
}

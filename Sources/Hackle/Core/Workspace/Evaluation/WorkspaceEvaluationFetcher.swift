import Foundation

protocol WorkspaceEvaluationFetcher {
    func workspace(user: HackleUser) -> WorkspaceEvaluation?
}

import Foundation

// WorkspaceFetcher.workspace(user)와 동명 오버로드이므로, concrete 타입 호출부는 반환 타입 명시가 필요하다.
protocol WorkspaceEvaluationFetcher {
    func workspace(user: HackleUser) -> WorkspaceEvaluation?
}

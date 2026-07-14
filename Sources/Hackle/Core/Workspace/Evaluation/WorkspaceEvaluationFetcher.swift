import Foundation

// java-core WorkspaceEvaluationFetcher는 WorkspaceFetcher.workspace(user)를 covariant return으로
// 정제하지만, Swift 프로토콜은 요구사항의 covariant 정제를 표현할 수 없어 독립 프로토콜 + 동명
// 오버로드가 된다. concrete 타입(WorkspaceEvaluationManager) 호출부는 반환 타입 명시가 필요하다.
protocol WorkspaceEvaluationFetcher {
    func workspace(user: HackleUser) -> WorkspaceEvaluation?
}

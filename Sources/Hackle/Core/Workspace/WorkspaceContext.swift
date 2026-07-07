import Foundation

/// android `WorkspaceContext`(`val workspace: Workspace`) 대응.
/// Swift는 protocol witness의 covariance를 허용하지 않아 PAT로 우회한다.
/// NOTE: `associatedtype WorkspaceType: Workspace` 제약은 existential witness
/// (`any WorkspaceConfig`)가 `Workspace`에 self-conform하지 않아 컴파일 불가 —
/// 제약 없이 선언한다 (의도는 "Workspace 계열"로 한정, 계약 문서 참조).
protocol WorkspaceContext {
    associatedtype WorkspaceType
    var workspace: WorkspaceType { get }
}

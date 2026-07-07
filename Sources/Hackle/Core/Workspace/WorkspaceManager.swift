import Foundation

/// java-core `WorkspaceFetcher`(metadata/workspace) + android `WorkspaceManager`(initialize)의 병합.
/// iOS는 단일 모듈이라 모듈 경계 분리가 불필요 (스펙 §5.2). java-core `WorkspaceFetcher.kt`의
/// iOS 대응 파일이 없는 것은 의도적.
protocol WorkspaceManager {
    func initialize()
    func metadata() -> WorkspaceMetadata?
    func workspace(user: HackleUser) -> Workspace?
}

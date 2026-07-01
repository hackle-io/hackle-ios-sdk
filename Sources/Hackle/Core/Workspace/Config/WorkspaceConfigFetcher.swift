import Foundation

protocol WorkspaceConfigFetcher: WorkspaceFetcher {
    func fetch() -> WorkspaceConfig?
}

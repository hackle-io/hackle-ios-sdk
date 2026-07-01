import Foundation

protocol WorkspaceConfigFetcher {
    func fetch() -> WorkspaceConfig?
}

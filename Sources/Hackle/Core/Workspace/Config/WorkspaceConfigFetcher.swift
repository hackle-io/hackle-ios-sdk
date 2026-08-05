import Foundation

protocol WorkspaceConfigFetcher {
    func workspace(user: HackleUser) -> WorkspaceConfig?
}

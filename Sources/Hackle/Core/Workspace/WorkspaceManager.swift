import Foundation

protocol WorkspaceManager {
    func initialize()
    func metadata() -> WorkspaceMetadata?
    func workspace(user: HackleUser) -> Workspace?
}

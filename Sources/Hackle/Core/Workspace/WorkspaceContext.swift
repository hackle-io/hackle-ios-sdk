import Foundation

protocol WorkspaceContext {
    associatedtype WorkspaceType
    var workspace: WorkspaceType { get }
}

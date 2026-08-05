import Foundation

protocol EvaluateRequest {
    var user: HackleUser { get }
    var workspace: Workspace { get }
    var entity: Entity { get }
    var record: Bool { get }
}

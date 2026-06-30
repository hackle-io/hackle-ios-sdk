import Foundation

protocol EvaluateResponse {
    var user: HackleUser { get }
    var workspace: Workspace { get }
    var evaluation: Evaluation { get }
    var references: [Evaluation] { get }
}

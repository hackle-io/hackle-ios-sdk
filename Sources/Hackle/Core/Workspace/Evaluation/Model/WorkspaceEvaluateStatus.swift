import Foundation

enum WorkspaceEvaluateStatus: String, Codable {
    case full = "FULL"
    case delta = "DELTA"
    case notModified = "NOT_MODIFIED"
}

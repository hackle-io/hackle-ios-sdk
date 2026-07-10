import Foundation

/// The evaluation mode.
///
/// - local: 클라이언트가 workspace 설정을 받아 로컬에서 평가한다. (기본)
/// - remote: 서버가 사전 평가한 결과를 클라이언트가 캐시해 조회한다.
@objc public enum EvaluationMode: Int, Sendable {
    case local
    case remote
}

extension EvaluationMode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .local: return "local"
        case .remote: return "remote"
        }
    }
}

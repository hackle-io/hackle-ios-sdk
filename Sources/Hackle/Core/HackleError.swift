import Foundation

enum HackleError: Error, Equatable, LocalizedError {
    case error(_ message: String)

    var errorDescription: String? {
        switch self {
        case .error(let message):
            return message
        }
    }
}

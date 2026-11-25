#if DEBUG
import Foundation

enum DevToolsTokenStore {
    static func newToken() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}
#endif

#if DEBUG
import Foundation

struct DevToolsHttpRequest: Equatable {
    let method: String
    let path: String
    let query: [String: String]

    static let maxHeaderBytes = 8192

    enum ParseResult: Equatable {
        case incomplete
        case tooLarge
        case malformed
        case complete(DevToolsHttpRequest)
    }

    static func parse(_ data: Data) -> ParseResult {
        guard let terminator = data.range(of: Data("\r\n\r\n".utf8)) else {
            return data.count < maxHeaderBytes ? .incomplete : .tooLarge
        }
        guard let header = String(data: data[data.startIndex..<terminator.lowerBound], encoding: .utf8) else {
            return .malformed
        }
        let requestLine = header.components(separatedBy: "\r\n")[0]
        let parts = requestLine.split(separator: " ", omittingEmptySubsequences: false)
        guard parts.count == 3, !parts[0].isEmpty, !parts[1].isEmpty, parts[2].hasPrefix("HTTP/1.") else {
            return .malformed
        }
        let target = parts[1]
        let path: Substring
        var query: [String: String] = [:]
        if let mark = target.firstIndex(of: "?") {
            path = target[..<mark]
            for pair in target[target.index(after: mark)...].split(separator: "&") {
                let keyValue = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard let key = keyValue[0].removingPercentEncoding,
                      let value = (keyValue.count > 1 ? keyValue[1] : "").removingPercentEncoding else {
                    return .malformed
                }
                query[key] = value
            }
        } else {
            path = target
        }
        return .complete(DevToolsHttpRequest(method: String(parts[0]), path: String(path), query: query))
    }
}
#endif

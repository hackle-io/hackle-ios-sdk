import Foundation

extension String {
    /// Escapes this string so that it can be embedded in JavaScript source as a string literal.
    /// The returned value includes the surrounding quotes.
    func javascriptStringLiteral() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: [self], options: []),
              let json = String(data: data, encoding: .utf8),
              json.count >= 2
        else {
            return #""""#
        }
        // ["..."] -> "..."
        return String(json.dropFirst().dropLast())
            .replacingOccurrences(of: "\u{2028}", with: #"\u2028"#)
            .replacingOccurrences(of: "\u{2029}", with: #"\u2029"#)
    }

    func escapedForJsSingleQuotedLiteral() -> String {
        self
            .replacingOccurrences(of: #"\"#, with: #"\\"#)
            .replacingOccurrences(of: "'", with: #"\'"#)
    }
}

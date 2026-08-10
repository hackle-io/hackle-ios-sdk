import Foundation
import Nimble
import Quick
@testable import Hackle

class StringJavascriptSpecs: QuickSpec {
    override class func spec() {
        it("javascriptStringLiteral") {
            expect("".javascriptStringLiteral()) == "\"\""
            expect("abc".javascriptStringLiteral()) == "\"abc\""
            expect("it's".javascriptStringLiteral()) == "\"it's\""
            expect("한글 😀".javascriptStringLiteral()) == "\"한글 😀\""
        }

        it("javascriptStringLiteral escapes json payload") {
            expect("{\"success\":true,\"message\":\"OK\"}".javascriptStringLiteral())
                == "\"{\\\"success\\\":true,\\\"message\\\":\\\"OK\\\"}\""
        }

        it("javascriptStringLiteral escapes control characters") {
            expect("a\\b".javascriptStringLiteral()) == "\"a\\\\b\""
            expect("line1\nline2".javascriptStringLiteral()) == "\"line1\\nline2\""
            expect("a\tb\rc".javascriptStringLiteral()) == "\"a\\tb\\rc\""
        }

        it("javascriptStringLiteral escapes javascript line terminators") {
            expect("a\u{2028}b".javascriptStringLiteral()) == "\"a\\u2028b\""
            expect("a\u{2029}b".javascriptStringLiteral()) == "\"a\\u2029b\""
        }
    }
}

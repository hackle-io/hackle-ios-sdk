import Foundation
@testable import Hackle

class MockInvocator: NSObject, HackleInvocator {
    var invocable = true
    var invokeResult = "{\"success\":true,\"message\":\"OK\"}"
    var invokedStrings: [String] = []
    var asyncInvokedStrings: [String] = []

    func isInvocableString(string: String) -> Bool {
        invocable
    }

    func invoke(string: String) -> String {
        invokedStrings.append(string)
        return invokeResult
    }

    func invoke(string: String, completionHandler: (String?) -> Void) {
        completionHandler(invoke(string: string))
    }

    func invokeAsync(string: String, completionHandler: @escaping (String?) -> Void) {
        asyncInvokedStrings.append(string)
        completionHandler(invoke(string: string))
    }
}

import Foundation

class InvocationRequest {
    let command: InvocationCommand
    let parameters: HackleInvokeParameters
    let browserProperties: [String: Any]

    init(command: InvocationCommand, parameters: HackleInvokeParameters, browserProperties: [String: Any]) {
        self.command = command
        self.parameters = parameters
        self.browserProperties = browserProperties
    }
}

extension InvocationRequest: CustomStringConvertible {
    var appContext: HackleAppContext {
        return HackleAppContext(browserProperties: browserProperties)
    }

    var description: String {
        return "InvocationRequest(command: \(command), parameters=\(parameters), browserProperties: \(browserProperties))"
    }

    static func parse(string: String) throws -> InvocationRequest {
        guard let dto = string.jsonObject() else {
            throw HackleError.error("Invalid invocation format")
        }
        guard let invocation = dto["_hackle"] as? [String: Any] else {
            throw HackleError.error("Invalid invocation format (missing: _hackle)")
        }
        guard let command = invocation["command"] as? String else {
            throw HackleError.error("Invalid invocation format (missing: command)")
        }
        guard let command = InvocationCommand(rawValue: command) else {
            throw HackleError.error("Unsupported InvocationCommand (\(command))")
        }
        return InvocationRequest(
            command: command,
            parameters: invocation["parameters"] as? HackleInvokeParameters ?? [:],
            browserProperties: invocation["browserProperties"] as? [String: Any] ?? [:]
        )
    }

    static func isInvocable(string: String) -> Bool {
        guard let dto = string.jsonObject() else {
            return false
        }
        guard let invocation = dto["_hackle"] as? [String: Any] else {
            return false
        }
        guard let command = invocation["command"] as? String else {
            return false
        }

        return !command.isEmpty
    }
}

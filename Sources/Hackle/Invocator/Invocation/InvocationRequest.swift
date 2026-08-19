import Foundation

struct InvocationRequest {
    let command: InvocationCommand
    let parameters: HackleInvokeParameters
    let browserProperties: [String: Any]
}

extension InvocationRequest {
    var appContext: HackleAppContext {
        return HackleAppContext(browserProperties: browserProperties)
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

    static func requestId(string: String) -> String? {
        guard let invocation = string.jsonObject()?["_hackle"] as? [String: Any],
              let requestId = invocation["requestId"]
        else {
            return nil
        }
        guard let requestId = requestId as? String else {
            Log.debug("requestId must be a string. [requestId=\(requestId)]")
            return nil
        }
        return requestId
    }
}

extension InvocationRequest: CustomStringConvertible {
    var description: String {
        return "InvocationRequest(command: \(command), parameters=\(parameters), browserProperties: \(browserProperties))"
    }
}

extension InvocationRequest {
    func parameters<T: Decodable>(_ type: T.Type = T.self) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: parameters.compactMapValues { $0 })
        return try JSONDecoder().decode(T.self, from: data)
    }
}

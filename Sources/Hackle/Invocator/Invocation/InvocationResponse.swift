import Foundation

struct InvocationResponse<T> {
    let isSuccess: Bool
    let message: String
    let data: T?
}

extension InvocationResponse {
    static func success() -> InvocationResponse<T> {
        return .init(isSuccess: true, message: "OK", data: nil)
    }

    static func success(data: T) -> InvocationResponse<T> {
        return .init(isSuccess: true, message: "OK", data: data)
    }

    static func error(error: Error) -> InvocationResponse<T> {
        return .init(isSuccess: false, message: error.localizedDescription, data: nil)
    }
}

extension InvocationResponse {
    func toJsonString() -> String {
        let dict = [
            "success": isSuccess,
            "message": message,
            "data": data as Any?
        ]
        let sanitized = dict.compactMapValues { $0 }
        return sanitized.toJson() ?? errorJson(message: "Error occurs while parsing response.")
    }

    private func errorJson(message: String) -> String {
        return "{\"success\": false,\"message\":\"\(message)\"}"
    }
}

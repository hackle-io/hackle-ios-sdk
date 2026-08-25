import Foundation

struct InvocationResponse<T> {
    let isSuccess: Bool
    let message: String
    let data: T?
    /// 비동기 처리의 완료 신호. user mutation 명령만 값을 가지며 직렬화되지 않는다.
    let task: Task<Void, Never>?
}

extension InvocationResponse {
    static func success() -> InvocationResponse<T> {
        return .init(isSuccess: true, message: "OK", data: nil, task: nil)
    }

    static func success(task: Task<Void, Never>) -> InvocationResponse<T> {
        return .init(isSuccess: true, message: "OK", data: nil, task: task)
    }

    static func success(data: T) -> InvocationResponse<T> {
        return .init(isSuccess: true, message: "OK", data: data, task: nil)
    }

    static func error(error: Error) -> InvocationResponse<T> {
        return .init(isSuccess: false, message: error.localizedDescription, data: nil, task: nil)
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
        guard let json = sanitized.toJson() else {
            Log.error("Failed to serialize invocation response. [data: \(type(of: data))]")
            return errorJson(message: "Error occurs while parsing response.")
        }
        return json
    }

    private func errorJson(message: String) -> String {
        return #"{"success": false,"message":"\#(message)"}"#
    }
}

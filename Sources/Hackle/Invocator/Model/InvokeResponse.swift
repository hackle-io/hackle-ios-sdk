import Foundation

class InvokeResponse {
    
    let success: Bool
    let message: String
    let data: Any?
    
    private init(success: Bool, message: String, data: Any? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
    
    func toJsonString() -> String {
        let dict = [
            "success": success,
            "message": message,
            "data": data
        ]
        let sanitized = dict.compactMapValues { $0 }
        return sanitized.toJson() ?? defaultJsonString(message: "Error occours while parsing response.")
    }
    
    func defaultJsonString(message: String) -> String {
        return "{\"success\": false,\"message\":\"\(message)\"}"
    }
}

extension InvokeResponse {
    
    static func success() -> InvokeResponse {
        return InvokeResponse(success: true, message: "OK")
    }
    
    static func success(_ data: Any?) -> InvokeResponse {
        return InvokeResponse(
            success: true,
            message: "OK",
            data: data
        )
    }
    
    static func error(_ message: String) -> InvokeResponse {
        return InvokeResponse(success: false, message: message)
    }
    
    static func error(_ error: Error) -> InvokeResponse {
        return InvokeResponse(success: false, message: error.localizedDescription)
    }
}

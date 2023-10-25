import Foundation

class BridgeResponse {
    
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
        return sanitized.toJson() ?? defaultJsonString(message: "Error occours while parsing bridge response.")
    }
    
    func defaultJsonString(message: String) -> String {
        return "{\"success\": false,\"message\":\"\(message)\"}"
    }
}

extension BridgeResponse {
    
    static func success() -> BridgeResponse {
        return BridgeResponse(success: true, message: "OK")
    }
    
    static func success(_ data: Double? = nil) -> BridgeResponse {
        guard let data = data else {
            return BridgeResponse(success: true, message: "OK")
        }
        return BridgeResponse(
            success: true,
            message: "OK",
            data: data
        )
    }
    
    static func success(_ data: Bool? = nil) -> BridgeResponse {
        guard let data = data else {
            return BridgeResponse(success: true, message: "OK")
        }
        return BridgeResponse(
            success: true,
            message: "OK",
            data: data
        )
    }
    
    static func success(_ data: String? = nil) -> BridgeResponse {
        guard let data = data else {
            return BridgeResponse(success: true, message: "OK")
        }
        return BridgeResponse(
            success: true,
            message: "OK",
            data: data
        )
    }
    
    static func success(_ data: [String: Any]? = nil) -> BridgeResponse {
        return BridgeResponse(
            success: true,
            message: "OK",
            data: data
        )
    }
    
    static func error(_ message: String) -> BridgeResponse {
        return BridgeResponse(success: false, message: message)
    }
    
    static func error(_ error: Error) -> BridgeResponse {
        return BridgeResponse(success: false, message: error.localizedDescription)
    }
}

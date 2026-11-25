#if DEBUG
import Foundation

struct DevToolsHttpResponse {
    static func make(status: Int, contentType: String?, body: Data) -> Data {
        var head = "HTTP/1.1 \(status) \(reasonPhrase(status))\r\n"
        if let contentType = contentType {
            head += "Content-Type: \(contentType)\r\n"
        }
        head += "Content-Length: \(body.count)\r\n"
        head += "Cache-Control: no-store\r\n"
        head += "Connection: close\r\n"
        head += "\r\n"
        var data = Data(head.utf8)
        data.append(body)
        return data
    }

    static func eventStreamHead() -> Data {
        var head = "HTTP/1.1 200 \(reasonPhrase(200))\r\n"
        head += "Content-Type: text/event-stream; charset=utf-8\r\n"
        head += "Cache-Control: no-store\r\n"
        head += "Connection: keep-alive\r\n"
        head += "\r\n"
        return Data(head.utf8)
    }

    static func reasonPhrase(_ status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 204: return "No Content"
        case 400: return "Bad Request"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 409: return "Conflict"
        case 431: return "Request Header Fields Too Large"
        case 503: return "Service Unavailable"
        default: return "Unknown"
        }
    }
}
#endif

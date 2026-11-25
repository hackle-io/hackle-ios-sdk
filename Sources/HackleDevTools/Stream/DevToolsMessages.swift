#if DEBUG
import Foundation
import UIKit

struct DevToolsAppInfo: Equatable {
    let id: String
    let name: String
    let version: String
    let deviceName: String
    let deviceModel: String
    let osVersion: String

    @MainActor
    static func current() -> DevToolsAppInfo {
        let info = Bundle.main.infoDictionary ?? [:]
        var systemInfo = utsname()
        uname(&systemInfo)
        let model = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
        return DevToolsAppInfo(
            id: Bundle.main.bundleIdentifier ?? "",
            name: (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String) ?? "",
            version: (info["CFBundleShortVersionString"] as? String) ?? "",
            deviceName: UIDevice.current.name,
            deviceModel: model,
            osVersion: UIDevice.current.systemVersion
        )
    }
}

enum DevToolsMessages {
    static let ping = Data(": ping\n\n".utf8)

    static func hello(app: DevToolsAppInfo, sdkVersion: String) -> String {
        let object: [String: Any] = [
            "type": "hello-hackle",
            "protocolVersion": 1,
            "app": ["platform": "ios", "id": app.id, "name": app.name, "version": app.version],
            "sdk": ["name": "ios-sdk", "version": sdkVersion],
            "device": ["name": app.deviceName, "model": app.deviceModel, "osVersion": app.osVersion]
        ]
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        return String(decoding: data, as: UTF8.self)
    }

    static func event(eventType: String, body: String) -> String {
        "{\"type\":\"event\",\"eventType\":\"\(eventType)\",\"event\":\(body)}"
    }

    static func log(insertId: String, level: String, timestamp: Int64, message: String) -> String {
        let object: [String: Any] = [
            "type": "log",
            "insertId": insertId,
            "level": level,
            "timestamp": timestamp,
            "message": message
        ]
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        return String(decoding: data, as: UTF8.self)
    }

    static func frame(_ json: String) -> Data {
        Data("data: \(json)\n\n".utf8)
    }
}
#endif

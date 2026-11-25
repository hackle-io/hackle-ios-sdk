#if DEBUG
import Foundation
import Hackle

enum DevToolsRoute: Equatable {
    case shell
    case events
    case workspace
    case setOverride(type: DevToolsOverrideType, key: Int64, variation: String)
    case resetOverride(type: DevToolsOverrideType, key: Int64)
    case resetAllOverrides(type: DevToolsOverrideType)
    case reject(status: Int)
}

enum DevToolsRouter {
    static func route(_ request: DevToolsHttpRequest, token: String) -> DevToolsRoute {
        let allowedMethods: Set<String>
        switch request.path {
        case "/", "/events", "/workspace":
            allowedMethods = ["GET"]
        case "/overrides":
            allowedMethods = ["PUT", "DELETE"]
        default:
            return .reject(status: 404)
        }
        guard allowedMethods.contains(request.method) else {
            return .reject(status: 405)
        }
        guard let requestToken = request.query["token"], !requestToken.isEmpty, requestToken == token else {
            return .reject(status: 403)
        }
        switch request.path {
        case "/":
            return .shell
        case "/events":
            return .events
        case "/workspace":
            return .workspace
        default:
            return overrides(request)
        }
    }

    private static func overrides(_ request: DevToolsHttpRequest) -> DevToolsRoute {
        guard let rawType = request.query["type"], let type = DevToolsOverrideType(rawValue: rawType) else {
            return .reject(status: 400)
        }
        let rawKey = request.query["key"]
        let key = rawKey.flatMap { Int64($0) }
        if rawKey != nil && key == nil {
            return .reject(status: 400)
        }
        if request.method == "PUT" {
            guard let key = key, let variation = request.query["variation"] else {
                return .reject(status: 400)
            }
            return .setOverride(type: type, key: key, variation: variation)
        }
        guard let key = key else {
            return .resetAllOverrides(type: type)
        }
        return .resetOverride(type: type, key: key)
    }
}
#endif

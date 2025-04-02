import Foundation

class BridgeInvocation {
    
    private enum ReservedKey: String {
        case hackle = "_hackle"
        case command = "command"
        case parameters = "parameters"
    }
    
    enum Command: String {
        case getSessionId = "getSessionId"
        case getUser = "getUser"
        case setUser = "setUser"
        case setUserId = "setUserId"
        case setDeviceId = "setDeviceId"
        case setUserProperty = "setUserProperty"
        case updateUserProperties = "updateUserProperties"
        case resetUser = "resetUser"
        case setPhoneNumber = "setPhoneNumber"
        case unsetPhoneNumber = "unsetPhoneNumber"
        case variation = "variation"
        case variationDetail = "variationDetail"
        case isFeatureOn = "isFeatureOn"
        case featureFlagDetail = "featureFlagDetail"
        case track = "track"
        case remoteConfig = "remoteConfig"
        case showUserExplorer = "showUserExplorer"
    }
    
    let command: Command
    let parameters: [String: Any]
    
    init(string: String) throws {
        guard let data = string.jsonObject() else {
            throw HackleError.error("Invalid JSON string provided.")
        }
        guard let invocation = data[ReservedKey.hackle.rawValue] as? [String: Any] else {
            throw HackleError.error("'\(ReservedKey.hackle)' key must provided.")
        }
        guard let command = invocation[ReservedKey.command.rawValue] as? String else {
            throw HackleError.error("'\(ReservedKey.command)' key must provided.")
        }
        guard let command = Command(rawValue: command) else {
            throw HackleError.error("Unsupported command string received.")
        }
        
        self.command = command
        self.parameters = invocation[ReservedKey.parameters.rawValue] as? [String: Any] ?? [:]
    }
    
    static func isInvocableString(string: String) -> Bool {
        guard let dict = string.jsonObject() else {
            return false
        }
        guard let payload = dict[ReservedKey.hackle.rawValue] as? [String: Any] else {
            return false
        }
        let command = payload[ReservedKey.command.rawValue] as? String
        return command != nil && command?.isEmpty == false
    }
}

import Foundation

class HackleBridge: NSObject {
    
    private enum ReservedKey: String {
        case hackle = "_hackle"
        case command = "_command"
        case parameters = "_parameters"
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
    
    static func invoke(string: String, completionHandler: (String?) -> Void) {
        let result = invoke(string: string)
        completionHandler(result)
    }
    
    static func invoke(string: String) -> String? {
        guard let app = Hackle.app() else { return nil }
        return invoke(app: app, string: string)
    }
}

extension HackleBridge {
    
    static func invoke(app: HackleAppProtocol, string: String) -> String? {
        guard let dict = string.jsonObject() else {
            return nil
        }
        guard let invocation = dict[ReservedKey.hackle.rawValue] as? [String: Any] else {
            return nil
        }
        guard let command = invocation[ReservedKey.command.rawValue] as? String else {
            return nil
        }
        let parameters = invocation[ReservedKey.parameters.rawValue] as? [String: Any] ?? [:]
        return invoke(app: app, command: command, parameters: parameters)
    }
    
    static func invoke(app: HackleAppProtocol, command: String, parameters: [String: Any]) -> String? {
        var returnValue: String?
        switch command {
        case "getSessionId":
            returnValue = app.sessionId
        case "getUser":
            returnValue = app.user.serialize()
        case "setUser":
            setUser(app: app, parameters: parameters)
        case "setUserId":
            setUserId(app: app, parameters: parameters)
        case "setDeviceId":
            setDeviceId(app: app, parameters: parameters)
        case "setUserProperty":
            setUserProperty(app: app, parameters: parameters)
        case "updateUserProperties":
            updateUserProperties(app: app, parameters: parameters)
        case "resetUser":
            app.resetUser()
        case "variation":
            returnValue = variation(app: app, parameters: parameters)
        case "variationDetail":
            returnValue = variationDetail(app: app, parameters: parameters)
        case "isFeatureOn":
            returnValue = isFeatureOn(app: app, parameters: parameters)
        case "featureFlagDetail":
            returnValue = featureFlagDetail(app: app, parameters: parameters)
        case "track":
            track(app: app, parameters: parameters)
        case "remoteConfig":
            returnValue = remoteConfig(app: app, parameters: parameters)
        case "showUserExplorer":
            app.showUserExplorer()
        case "hideUserExplorer":
            app.hideUserExplorer()
        default:
            returnValue = nil
        }
        return returnValue
    }
}

fileprivate extension HackleBridge {
    
    static func setUser(app: HackleAppProtocol, parameters: [String: Any]) {
        guard let data = parameters["user"] as? [String: Any] else { return }
        if let user = User.deserialize(data: data) {
            app.setUser(user: user)
        }
    }
    
    static func setUserId(app: HackleAppProtocol, parameters: [String: Any]) {
        if parameters.keys.contains("userId") {
            let userId = parameters["userId"] as? String
            app.setUserId(userId: userId)
        }
    }
    
    static func setDeviceId(app: HackleAppProtocol, parameters: [String: Any]) {
        if parameters.keys.contains("deviceId") {
            if let deviceId = parameters["deviceId"] as? String {
                app.setDeviceId(deviceId: deviceId)
            }
        }
    }
    
    static func setUserProperty(app: HackleAppProtocol, parameters: [String: Any]) {
        guard let key = parameters["key"] as? String else { return }
        let value = parameters["value"]
        app.setUserProperty(key: key, value: value)
    }
    
    static func updateUserProperties(app: HackleAppProtocol, parameters: [String: Any]) {
        guard let operations = parameters["operations"] as? [String: [String: Any]] else { return }
        let builder = PropertyOperationsBuilder()
        for (operation, properties) in operations {
            guard let operation = PropertyOperation(rawValue: operation) else {
                continue
            }
            
            switch operation {
            case PropertyOperation.set:
                properties.forEach{ key, value in builder.set(key, value) }
            case PropertyOperation.setOnce:
                properties.forEach{ key, value in builder.setOnce(key, value) }
            case PropertyOperation.unset:
                properties.forEach{ key, value in builder.unset(key) }
            case PropertyOperation.increment:
                properties.forEach{ key, value in builder.increment(key, value) }
            case PropertyOperation.append:
                properties.forEach{ key, value in builder.append(key, value) }
            case .appendOnce:
                properties.forEach{ key, value in builder.appendOnce(key, value) }
            case .prepend:
                properties.forEach{ key, value in builder.prepend(key, value) }
            case .prependOnce:
                properties.forEach{ key, value in builder.prependOnce(key, value) }
            case .remove:
                properties.forEach{ key, value in builder.remove(key, value) }
            case .clearAll:
                properties.forEach{ key, value in builder.clearAll() }
            }
        }
        app.updateUserProperties(operations: builder.build())
    }
    
    static func variation(app: HackleAppProtocol, parameters: [String: Any]) -> String? {
        guard let experimentKey = parameters["experimentKey"] as? Int else {
            return nil
        }
        let defaultVariation = parameters["defaultVariation"] as? String ?? "A"
        if let userId = parameters["userId"] as? String {
            let result = app.variation(
                experimentKey: experimentKey,
                userId: userId,
                defaultVariation: defaultVariation
            )
            return result
        }
        if parameters.keys.contains("user") {
            if let data = parameters["user"] as? [String: Any] {
                if let user = User.deserialize(data: data) {
                    let result = app.variation(
                        experimentKey: experimentKey,
                        user: user,
                        defaultVariation: defaultVariation
                    )
                    return result
                }
            }
        }
        return app.variation(experimentKey: experimentKey, defaultVariation: defaultVariation)
    }
    
    static func variationDetail(app: HackleAppProtocol, parameters: [String: Any]) -> String? {
        guard let experimentKey = parameters["experimentKey"] as? Int else {
            return nil
        }
        let defaultVariation = parameters["defaultVariation"] as? String ?? "A"
        if let userId = parameters["userId"] as? String {
            let decision = app.variationDetail(
                experimentKey: experimentKey,
                userId: userId,
                defaultVariation: defaultVariation
            )
            return decision.serialize()
        }
        if parameters.keys.contains("user") {
            if let data = parameters["user"] as? [String: Any] {
                if let user = User.deserialize(data: data) {
                    let decision = app.variationDetail(
                        experimentKey: experimentKey,
                        user: user,
                        defaultVariation: defaultVariation
                    )
                    return decision.serialize()
                }
            }
        }
        let decision = app.variationDetail(experimentKey: experimentKey, defaultVariation: defaultVariation)
        return decision.serialize()
    }
    
    static func isFeatureOn(app: HackleAppProtocol, parameters: [String: Any]) -> String? {
        guard let featureKey = parameters["featureKey"] as? Int else {
            return nil
        }
        if let userId = parameters["userId"] as? String {
            let result = app.isFeatureOn(featureKey: featureKey, userId: userId)
            return result.description
        }
        if parameters.keys.contains("user") {
            if let data = parameters["user"] as? [String: Any] {
                if let user = User.deserialize(data: data) {
                    let result = app.isFeatureOn(featureKey: featureKey, user: user)
                    return result.description
                }
            }
        }
        let result = app.isFeatureOn(featureKey: featureKey)
        return result.description
    }
    
    static func featureFlagDetail(app: HackleAppProtocol, parameters: [String: Any]) -> String? {
        guard let featureKey = parameters["featureKey"] as? Int else {
            return nil
        }
        if let userId = parameters["userId"] as? String {
            let decision = app.featureFlagDetail(featureKey: featureKey, userId: userId)
            return decision.serialize()
        }
        if parameters.keys.contains("user") {
            if let data = parameters["user"] as? [String: Any] {
                if let user = User.deserialize(data: data) {
                    let decision = app.featureFlagDetail(featureKey: featureKey, user: user)
                    return decision.serialize()
                }
            }
        }
        let decision = app.featureFlagDetail(featureKey: featureKey)
        return decision.serialize()
    }
    
    static func track(app: HackleAppProtocol, parameters: [String: Any]) {
        guard let data = parameters["event"] as? [String: Any] else { return }
        guard let event = Event.deserialize(data: data) else { return }
        if let userId = parameters["userId"] as? String {
            app.track(event: event, userId: userId)
            return
        }
        if parameters.keys.contains("user") {
            if let data = parameters["user"] as? [String: Any] {
                if let user = User.deserialize(data: data) {
                    app.track(event: event, user: user)
                    return
                }
            }
        }
        app.track(event: event)
    }
    
    static func remoteConfig(app: HackleAppProtocol, parameters: [String: Any]) -> String? {
        var user: User? = nil
        if let userId = parameters["userId"] as? String {
            user = User.builder()
                .userId(userId)
                .build()
        } else if parameters.keys.contains("user") {
            if let data = parameters["user"] as? [String: Any] {
                user = User.deserialize(data: data)
            }
        }
        
        let config: HackleRemoteConfig
        if let user = user {
            config = app.remoteConfig(user: user)
        } else {
            config = app.remoteConfig()
        }
        
        guard let key = parameters["key"] as? String else {
            return nil
        }
        guard let valueType = parameters["valueType"] as? String else {
            return nil
        }
        
        switch valueType {
        case "string":
            guard let defaultValue = parameters["defaultValue"] as? String else {
                return nil
            }
            return config.getString(forKey: key, defaultValue: defaultValue)
        case "number":
            guard let defaultValue = parameters["defaultValue"] as? Double else {
                return nil
            }
            let value = config.getDouble(forKey: key, defaultValue: defaultValue)
            return value.description
        case "boolean":
            guard let defaultValue = parameters["defaultValue"] as? Bool else {
                return nil
            }
            let value = config.getBool(forKey: key, defaultValue: defaultValue)
            return value.description
        default:
            return nil
        }
    }
}

fileprivate extension Decision {
    
    func serialize() -> String? {
        var dictionary: [String: Any] = [:]
        if let experiment = experiment {
            dictionary["experiment"] = [
                "key": experiment.key,
                "version": experiment.version
            ] as [String: Any]
        }
        dictionary["variation"] = variation
        dictionary["reason"] = reason
        dictionary["config"] = parameters
        let sanitized = dictionary.compactMapValues { $0 }
        return sanitized.toJson()
    }
}

fileprivate extension FeatureFlagDecision {
    
    func serialize() -> String? {
        var dictionary: [String: Any] = [:]
        if let featureFlag = featureFlag {
            dictionary["featureFlag"] = [
                "key": featureFlag.key,
                "version": featureFlag.version
            ] as [String: Any]
        }
        dictionary["isOn"] = isOn
        dictionary["reason"] = reason
        dictionary["parameters"] = parameters
        let sanitized = dictionary.compactMapValues { $0 }
        return sanitized.toJson()
    }
}

fileprivate extension Event {
    
    static func deserialize(data: [String: Any]) -> Event? {
        guard let key = data["key"] as? String else {
            return nil
        }
        let builder = Event.builder(key)
        if let value = data["value"] as? Double {
            builder.value(value)
        }
        if let properties = data["properties"] as? [String: Any] {
            builder.properties(properties)
        }
        return builder.build()
    }
}

fileprivate extension User {
    
    func serialize() -> String? {
        let dictionary: [String: Any?] = [
            "id": id,
            "userId": userId,
            "deviceId": deviceId,
            "identifiers": identifiers,
            "properties": properties
        ]
        let sanitized = dictionary.compactMapValues { $0 }
        return sanitized.toJson()
    }
    
    static func deserialize(data: [String: Any]) -> User? {
        let builder = User.builder()
        if let id = data["id"] as? String {
            builder.id(id)
        }
        if let userId = data["userId"] as? String {
            builder.userId(userId)
        }
        if let deviceId = data["deviceId"] as? String {
            builder.deviceId(deviceId)
        }
        if let identifiers = data["identifiers"] as? [String: String] {
            builder.identifiers(identifiers)
        }
        if let properties = data["properties"] as? [String: Any] {
            builder.properties(properties)
        }
        return builder.build()
    }
}

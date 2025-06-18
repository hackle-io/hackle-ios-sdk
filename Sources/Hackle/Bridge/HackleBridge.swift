import Foundation

class HackleBridge: NSObject {

    private let app: HackleAppProtocol

    init(app: HackleAppProtocol) {
        self.app = app
    }

    func isInvocableString(string: String) -> Bool {
        return BridgeInvocation.isInvocableString(string: string)
    }

    func invoke(string: String, completionHandler: (String?) -> Void) {
        let result = invoke(string: string)
        completionHandler(result)
    }

    func invoke(string: String) -> String {
        let response: BridgeResponse
        do {
            let invocation = try BridgeInvocation(string: string)
            response = try invoke(
                command: invocation.command,
                parameters: invocation.parameters
            )
        } catch let e {
            response = .error(e)
        }
        return response.toJsonString()
    }
}

extension HackleBridge {

    private func invoke(command: BridgeInvocation.Command, parameters: [String: Any]) throws -> BridgeResponse {
        switch command {
        case .getSessionId:
            return .success(app.sessionId)
        case .getUser:
            return .success(app.user.toDto())
        case .setUser:
            try setUser(parameters: parameters)
            return .success()
        case .setUserId:
            try setUserId(parameters: parameters)
            return .success()
        case .setDeviceId:
            try setDeviceId(parameters: parameters)
            return .success()
        case .setUserProperty:
            try setUserProperty(parameters: parameters)
            return .success()
        case .updateUserProperties:
            try updateUserProperties(parameters: parameters)
            return .success()
        case .updatePushSubscriptions:
            try updatePushSubscriptions(parameters: parameters)
            return .success()
        case .updateSmsSubscriptions:
            try updateSmsSubscriptions(parameters: parameters)
            return .success()
        case .updateKakaoSubscriptions:
            try updateKakaoSubscriptions(parameters: parameters)
            return .success()
        case .resetUser:
            app.resetUser()
            return .success()
        case .setPhoneNumber:
            try setPhoneNumber(parameters: parameters)
            return .success()
        case .unsetPhoneNumber:
            app.unsetPhoneNumber()
            return .success()
        case .variation:
            let data = try variation(parameters: parameters)
            return .success(data)
        case .variationDetail:
            let data = try variationDetail(parameters: parameters)
            return .success(data)
        case .isFeatureOn:
            let data = try isFeatureOn(parameters: parameters)
            return .success(data)
        case .featureFlagDetail:
            let data = try featureFlagDetail(parameters: parameters)
            return .success(data)
        case .track:
            try track(parameters: parameters)
            return .success()
        case .remoteConfig:
            let data = try remoteConfig(parameters: parameters)
            return .success(data)
        case .showUserExplorer:
            app.showUserExplorer()
            return .success()
        case .hideUserExplorer:
            app.hideUserExplorer()
            return .success()
        }
    }
}

fileprivate extension HackleBridge {

    private func setUser(parameters: [String: Any]) throws {
        guard let data = parameters["user"] as? [String: Any] else {
            throw HackleError.error("Valid 'user' parameter must be provided.")
        }
        if let user = User.from(dto: data) {
            app.setUser(user: user)
        }
    }

    private func setUserId(parameters: [String: Any]) throws {
        guard let userId = parameters["userId"] as? String else {
            throw HackleError.error("Valid 'userId' parameter must be provided.")
        }
        app.setUserId(userId: userId)
    }

    private func setDeviceId(parameters: [String: Any]) throws {
        guard let deviceId = parameters["deviceId"] as? String else {
            throw HackleError.error("Valid 'deviceId' parameter must be provided.")
        }
        app.setDeviceId(deviceId: deviceId)
    }

    private func setUserProperty(parameters: [String: Any]) throws {
        guard let key = parameters["key"] as? String else {
            throw HackleError.error("Valid 'key' parameter must be provided.")
        }
        let value = parameters["value"]
        app.setUserProperty(key: key, value: value)
    }

    private func updateUserProperties(parameters: [String: Any]) throws {
        guard let data = parameters["operations"] as? [String: [String: Any]] else {
            throw HackleError.error("Valid 'operations' parameter must be provided.")
        }
        let operations = PropertyOperations.from(dto: data)
        app.updateUserProperties(operations: operations)
    }
    
    private func updatePushSubscriptions(parameters: [String: Any]) throws {
        guard let data = parameters["operations"] as? [String: String] else {
            throw HackleError.error("Valid 'subscriptions' parameter must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: data)
        app.updatePushSubscriptions(operations: operations)
    }
    
    private func updateSmsSubscriptions(parameters: [String: Any]) throws {
        guard let data = parameters["operations"] as? [String: String] else {
            throw HackleError.error("Valid 'subscriptions' parameter must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: data)
        app.updateSmsSubscriptions(operations: operations)
    }
    
    private func updateKakaoSubscriptions(parameters: [String: Any]) throws {
        guard let data = parameters["operations"] as? [String: String] else {
            throw HackleError.error("Valid 'subscriptions' parameter must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: data)
        app.updateKakaoSubscriptions(operations: operations)
    }
    
    private func setPhoneNumber(parameters: [String: Any]) throws {
        guard let phoneNumber = parameters["phoneNumber"] as? String else {
            throw HackleError.error("Valid 'phoneNumber' parameter must be provided.")
        }
        app.setPhoneNumber(phoneNumber: phoneNumber)
    }

    private func variation(parameters: [String: Any]) throws -> String? {
        guard let experimentKey = parameters["experimentKey"] as? Int else {
            throw HackleError.error("Valid 'experimentKey' parameter must be provided.")
        }
        let defaultVariation = parameters["defaultVariation"] as? String ?? "A"
        if let userId = parameters["user"] as? String {
            let result = app.variation(
                experimentKey: experimentKey,
                userId: userId,
                defaultVariation: defaultVariation
            )
            return result
        }
        if let data = parameters["user"] as? [String: Any] {
            if let user = User.from(dto: data) {
                let result = app.variation(
                    experimentKey: experimentKey,
                    user: user,
                    defaultVariation: defaultVariation
                )
                return result
            }
        }
        return app.variation(experimentKey: experimentKey, defaultVariation: defaultVariation)
    }

    private func variationDetail(parameters: [String: Any]) throws -> DecisionDto {
        guard let experimentKey = parameters["experimentKey"] as? Int else {
            throw HackleError.error("Valid 'experimentKey' parameter must be provided.")
        }
        let defaultVariation = parameters["defaultVariation"] as? String ?? "A"
        if let userId = parameters["user"] as? String {
            let decision = app.variationDetail(
                experimentKey: experimentKey,
                userId: userId,
                defaultVariation: defaultVariation
            )
            return decision.toDto()
        }
        if let data = parameters["user"] as? [String: Any] {
            if let user = User.from(dto: data) {
                let decision = app.variationDetail(
                    experimentKey: experimentKey,
                    user: user,
                    defaultVariation: defaultVariation
                )
                return decision.toDto()
            }
        }
        let decision = app.variationDetail(experimentKey: experimentKey, defaultVariation: defaultVariation)
        return decision.toDto()
    }

    private func isFeatureOn(parameters: [String: Any]) throws -> Bool {
        guard let featureKey = parameters["featureKey"] as? Int else {
            throw HackleError.error("Valid 'featureKey' parameter must be provided.")
        }
        if let userId = parameters["user"] as? String {
            let result = app.isFeatureOn(featureKey: featureKey, userId: userId)
            return result
        }
        if let data = parameters["user"] as? [String: Any] {
            if let user = User.from(dto: data) {
                let result = app.isFeatureOn(featureKey: featureKey, user: user)
                return result
            }
        }
        let result = app.isFeatureOn(featureKey: featureKey)
        return result
    }

    private func featureFlagDetail(parameters: [String: Any]) throws -> FeatureFlagDecisionDto {
        guard let featureKey = parameters["featureKey"] as? Int else {
            throw HackleError.error("Valid 'featureKey' parameter must be provided.")
        }
        if let userId = parameters["user"] as? String {
            let decision = app.featureFlagDetail(featureKey: featureKey, userId: userId)
            return decision.toDto()
        }
        if let data = parameters["user"] as? [String: Any] {
            if let user = User.from(dto: data) {
                let decision = app.featureFlagDetail(featureKey: featureKey, user: user)
                return decision.toDto()
            }
        }
        let decision = app.featureFlagDetail(featureKey: featureKey)
        return decision.toDto()
    }

    private func track(parameters: [String: Any]) throws {
        if let eventKey = parameters["event"] as? String {
            track(eventKey: eventKey, parameters: parameters)
        } else if let data = parameters["event"] as? [String: Any] {
            guard let event = Event.from(dto: data) else {
                throw HackleError.error("Valid 'event' parameter must be provided.")
            }
            track(event: event, parameters: parameters)
        } else {
            throw HackleError.error("Valid 'event' parameter must be provided.")
        }
    }

    private func track(eventKey: String, parameters: [String: Any]) {
        if let userId = parameters["user"] as? String {
            app.track(eventKey: eventKey, userId: userId)
            return
        }
        if let data = parameters["user"] as? [String: Any] {
            if let user = User.from(dto: data) {
                app.track(eventKey: eventKey, user: user)
                return
            }
        }
        app.track(eventKey: eventKey)
    }

    private func track(event: Event, parameters: [String: Any]) {
        if let userId = parameters["user"] as? String {
            app.track(event: event, userId: userId)
            return
        }
        if let data = parameters["user"] as? [String: Any] {
            if let user = User.from(dto: data) {
                app.track(event: event, user: user)
                return
            }
        }
        app.track(event: event)
    }

    private func remoteConfig(parameters: [String: Any]) throws -> String? {
        var user: User? = nil
        if let userId = parameters["user"] as? String {
            user = User.builder()
                .userId(userId)
                .build()
        } else if let data = parameters["user"] as? [String: Any] {
            user = User.from(dto: data)
        }

        let config: HackleRemoteConfig
        if let user = user {
            config = app.remoteConfig(user: user)
        } else {
            config = app.remoteConfig()
        }

        guard let key = parameters["key"] as? String else {
            throw HackleError.error("Valid 'key' parameter must be provided.")
        }
        guard let valueType = parameters["valueType"] as? String else {
            throw HackleError.error("Valid 'valueType' parameter must be provided.")
        }

        switch valueType {
        case "string":
            guard let defaultValue = parameters["defaultValue"] as? String else {
                throw HackleError.error("Valid 'defaultValue' parameter must be provided.")
            }
            return config.getString(forKey: key, defaultValue: defaultValue)
        case "number":
            guard let defaultValue = parameters["defaultValue"] as? Double else {
                throw HackleError.error("Valid 'defaultValue' parameter must be provided.")
            }
            let value = config.getDouble(forKey: key, defaultValue: defaultValue)
            return value.description
        case "boolean":
            guard let defaultValue = parameters["defaultValue"] as? Bool else {
                throw HackleError.error("Valid 'defaultValue' parameter must be provided.")
            }
            let value = config.getBool(forKey: key, defaultValue: defaultValue)
            return value.description
        default:
            throw HackleError.error("Unsupport 'valueType' value provided.")
        }
    }
}

typealias UserDto = [String: Any]
typealias EventDto = [String: Any]
typealias DecisionDto = [String: Any]
typealias FeatureFlagDecisionDto = [String: Any]
typealias PropertyOperationsDto = [String: [String: Any]]
typealias HackleSubscriptionOperationsDto = [String: String]

extension User {

    func toDto() -> UserDto {
        let dictionary: [String: Any?] = [
            "id": id,
            "userId": userId,
            "deviceId": deviceId,
            "identifiers": identifiers,
            "properties": properties
        ]
        let sanitized = dictionary.compactMapValues {
            $0
        }
        return sanitized
    }

    static func from(dto: UserDto) -> User? {
        let builder = User.builder()
        if let id = dto["id"] as? String {
            builder.id(id)
        }
        if let userId = dto["userId"] as? String {
            builder.userId(userId)
        }
        if let deviceId = dto["deviceId"] as? String {
            builder.deviceId(deviceId)
        }
        if let identifiers = dto["identifiers"] as? [String: String] {
            builder.identifiers(identifiers)
        }
        if let properties = dto["properties"] as? [String: Any] {
            builder.properties(properties)
        }
        return builder.build()
    }
}

extension Event {

    static func from(dto: EventDto) -> Event? {
        guard let key = dto["key"] as? String else {
            return nil
        }
        let builder = Event.builder(key)
        if let value = dto["value"] as? Double {
            builder.value(value)
        }
        if let properties = dto["properties"] as? [String: Any] {
            builder.properties(properties)
        }
        return builder.build()
    }
}

extension Decision {

    func toDto() -> DecisionDto {
        var dictionary: [String: Any] = [:]
        dictionary["variation"] = variation
        dictionary["reason"] = reason
        dictionary["config"] = ["parameters": parameters]
        return dictionary.compactMapValues {
            $0
        }
    }
}

extension FeatureFlagDecision {

    func toDto() -> FeatureFlagDecisionDto {
        var dictionary: [String: Any] = [:]
        dictionary["isOn"] = isOn
        dictionary["reason"] = reason
        dictionary["config"] = ["parameters": parameters]
        return dictionary.compactMapValues {
            $0
        }
    }
}

extension PropertyOperations {

    static func from(dto: PropertyOperationsDto) -> PropertyOperations {
        let builder = PropertyOperationsBuilder()
        for (operation, properties) in dto {
            guard let operation = PropertyOperation(rawValue: operation) else {
                continue
            }

            switch operation {
            case PropertyOperation.set:
                properties.forEach { key, value in
                    builder.set(key, value)
                }
            case PropertyOperation.setOnce:
                properties.forEach { key, value in
                    builder.setOnce(key, value)
                }
            case PropertyOperation.unset:
                properties.forEach { key, value in
                    builder.unset(key)
                }
            case PropertyOperation.increment:
                properties.forEach { key, value in
                    builder.increment(key, value)
                }
            case PropertyOperation.append:
                properties.forEach { key, value in
                    builder.append(key, value)
                }
            case .appendOnce:
                properties.forEach { key, value in
                    builder.appendOnce(key, value)
                }
            case .prepend:
                properties.forEach { key, value in
                    builder.prepend(key, value)
                }
            case .prependOnce:
                properties.forEach { key, value in
                    builder.prependOnce(key, value)
                }
            case .remove:
                properties.forEach { key, value in
                    builder.remove(key, value)
                }
            case .clearAll:
                properties.forEach { key, value in
                    builder.clearAll()
                }
            }
        }
        return builder.build()
    }
}

extension HackleSubscriptionOperations {
    
    static func from(dto: HackleSubscriptionOperationsDto) -> HackleSubscriptionOperations {
        let builder = HackleSubscriptionOperations.builder()
        for (key, value) in dto {
            guard let status = HackleSubscriptionStatus(rawValue: value) else {
                continue
            }
            builder.set(key, status: status)
        }
        return builder.build()
    }
}

import Foundation

class HackleBridge: NSObject, HackleAppBridge {

    private let hackleAppCore: HackleAppCore

    init(hackleAppCore: HackleAppCore) {
        self.hackleAppCore = hackleAppCore
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
                parameters: invocation.parameters,
                browserProperties: invocation.browserProperties
            )
        } catch let e {
            response = .error(e)
        }
        return response.toJsonString()
    }
}

extension HackleBridge {

    private func invoke(command: BridgeInvocation.Command, parameters: HackleBridgeParameters, browserProperties: HackleBrowserProperties) throws -> BridgeResponse {
        let hackleAppContext = HackleAppContext.create(browserProperties: browserProperties)
        switch command {
        case .getSessionId:
            return .success(hackleAppCore.sessionId)
        case .getUser:
            return .success(hackleAppCore.user.toDto())
        case .setUser:
            try setUser(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .setUserId:
            try setUserId(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .setDeviceId:
            try setDeviceId(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .setUserProperty:
            try setUserProperty(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .updateUserProperties:
            try updateUserProperties(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .updatePushSubscriptions:
            try updatePushSubscriptions(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .updateSmsSubscriptions:
            try updateSmsSubscriptions(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .updateKakaoSubscriptions:
            try updateKakaoSubscriptions(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .resetUser:
            hackleAppCore.resetUser(hackleAppContext: hackleAppContext, completion: {})
            return .success()
        case .setPhoneNumber:
            try setPhoneNumber(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .unsetPhoneNumber:
            hackleAppCore.unsetPhoneNumber(hackleAppContext: hackleAppContext, completion: {})
            return .success()
        case .variation:
            let data = try variation(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success(data)
        case .variationDetail:
            let data = try variationDetail(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success(data)
        case .isFeatureOn:
            let data = try isFeatureOn(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success(data)
        case .featureFlagDetail:
            let data = try featureFlagDetail(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success(data)
        case .track:
            try track(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .remoteConfig:
            let data = try remoteConfig(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success(data)
        case .setCurrentScreen:
            try setCurrentScreen(parameters: parameters, hackleAppContext: hackleAppContext)
            return .success()
        case .showUserExplorer:
            hackleAppCore.showUserExplorer()
            return .success()
        case .hideUserExplorer:
            hackleAppCore.hideUserExplorer()
            return .success()
        }
    }
}

fileprivate extension HackleBridge {

    private func setUser(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let data = parameters.userAsDictionary() else {
            throw HackleError.error("Valid 'user' parameter must be provided.")
        }
        if let user = User.from(dto: data) {
            hackleAppCore.setUser(user: user, hackleAppContext: hackleAppContext, completion: {})
        }
    }

    private func setUserId(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let userId = parameters.userId() else {
            throw HackleError.error("Valid 'userId' parameter must be provided.")
        }
        hackleAppCore.setUserId(userId: userId, hackleAppContext: hackleAppContext, completion: {})
    }

    private func setDeviceId(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let deviceId = parameters.deviceId() else {
            throw HackleError.error("Valid 'deviceId' parameter must be provided.")
        }
        hackleAppCore.setDeviceId(deviceId: deviceId, hackleAppContext: hackleAppContext, completion: {})
    }

    private func setUserProperty(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let key = parameters.key(),
              let value = parameters.value() else {
            throw HackleError.error("Valid 'key' & 'value' parameter must be provided.")
        }
        let operations = PropertyOperationsBuilder().set(key, value).build()
        
        hackleAppCore.updateUserProperties(operations: operations, hackleAppContext: hackleAppContext, completion: {})
    }

    private func updateUserProperties(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let dto = parameters.propertyOperationDto() else {
            throw HackleError.error("Valid 'operations' parameter must be provided.")
        }
        let operations = PropertyOperations.from(dto: dto)
        hackleAppCore.updateUserProperties(operations: operations, hackleAppContext: hackleAppContext, completion: {})
    }
    
    private func updatePushSubscriptions(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let dto = parameters.subscriptionOperationDto() else {
            throw HackleError.error("Valid 'subscriptions' parameter must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: dto)
        hackleAppCore.updatePushSubscriptions(operations: operations, hackleAppContext: hackleAppContext)
    }
    
    private func updateSmsSubscriptions(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let dto = parameters.subscriptionOperationDto() else {
            throw HackleError.error("Valid 'subscriptions' parameter must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: dto)
        hackleAppCore.updateSmsSubscriptions(operations: operations, hackleAppContext: hackleAppContext)
    }
    
    private func updateKakaoSubscriptions(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let dto = parameters.subscriptionOperationDto() else {
            throw HackleError.error("Valid 'subscriptions' parameter must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: dto)
        hackleAppCore.updateKakaoSubscriptions(operations: operations, hackleAppContext: hackleAppContext)
    }
    
    private func setPhoneNumber(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let phoneNumber = parameters.phoneNumber() else {
            throw HackleError.error("Valid 'phoneNumber' parameter must be provided.")
        }
        hackleAppCore.setPhoneNumber(phoneNumber: phoneNumber, hackleAppContext: hackleAppContext, completion: {})
    }

    private func variation(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws -> String? {
        guard let experimentKey = parameters.experimentKey() else {
            throw HackleError.error("Valid 'experimentKey' parameter must be provided.")
        }
        let defaultVariation = parameters.defaultVariation()
        let result = hackleAppCore.variationDetail(
            experimentKey: experimentKey,
            user: parameters.user(),
            defaultVariation: defaultVariation,
            hackleAppContext: hackleAppContext
        )
        return result.variation
    }

    private func variationDetail(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws -> DecisionDto {
        guard let experimentKey = parameters.experimentKey() else {
            throw HackleError.error("Valid 'experimentKey' parameter must be provided.")
        }
        let defaultVariation = parameters.defaultVariation()
        let result = hackleAppCore.variationDetail(
            experimentKey: experimentKey,
            user: parameters.user(),
            defaultVariation: defaultVariation,
            hackleAppContext: hackleAppContext
        )
        return result.toDto()
    }

    private func isFeatureOn(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws -> Bool {
        guard let featureKey = parameters.featureKey() else {
            throw HackleError.error("Valid 'featureKey' parameter must be provided.")
        }
        let result = hackleAppCore.featureFlagDetail(featureKey: featureKey, user: parameters.user(), hackleAppContext: hackleAppContext)
        return result.isOn
    }

    private func featureFlagDetail(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws -> FeatureFlagDecisionDto {
        guard let featureKey = parameters.featureKey() else {
            throw HackleError.error("Valid 'featureKey' parameter must be provided.")
        }
        let result = hackleAppCore.featureFlagDetail(featureKey: featureKey, user: parameters.user(), hackleAppContext: hackleAppContext)
        return result.toDto()
    }

    private func track(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let event = parameters.event() else {
            throw HackleError.error("Valid 'event' parameter must be provided.")
        }
        
        hackleAppCore.track(event: event, user: parameters.user(), hackleAppContext: hackleAppContext)
    }

    private func remoteConfig(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws -> String? {
        guard let key = parameters.key() else {
            throw HackleError.error("Valid 'key' parameter must be provided.")
        }
        guard let valueType = parameters.valueType() else {
            throw HackleError.error("Valid 'valueType' parameter must be provided.")
        }
        
        let user: User? = parameters.userWithUserId()
        let config = hackleAppCore.remoteConfig(user: user, hackleAppContext: hackleAppContext)

        switch valueType {
        case "string":
            guard let defaultValue = parameters.defaultStringValue() else {
                throw HackleError.error("Valid 'defaultValue' parameter must be provided.")
            }
            return config.getString(forKey: key, defaultValue: defaultValue)
        case "number":
            guard let defaultValue = parameters.defaultDoubleValue() else {
                throw HackleError.error("Valid 'defaultValue' parameter must be provided.")
            }
            let value = config.getDouble(forKey: key, defaultValue: defaultValue)
            return value.description
        case "boolean":
            guard let defaultValue = parameters.defaultBoolValue() else {
                throw HackleError.error("Valid 'defaultValue' parameter must be provided.")
            }
            let value = config.getBool(forKey: key, defaultValue: defaultValue)
            return value.description
        default:
            throw HackleError.error("Unsupport 'valueType' value provided.")
        }
    }
    
    private func setCurrentScreen(parameters: HackleBridgeParameters, hackleAppContext: HackleAppContext) throws {
        guard let screenName = parameters.screenName() else {
            throw HackleError.error("Valid 'screenName' parameter must be provided.")
        }
        guard let className = parameters.className() else {
            throw HackleError.error("Valid 'className' parameter must be provided.")
        }
        
        hackleAppCore.setCurrentScreen(screen: Screen(name: screenName, className: className), hackleAppContext: hackleAppContext)
    }
}

import Foundation

class DefaultHackleInvocator: NSObject, HackleInvocator {

    private let hackleAppCore: HackleAppCore

    init(hackleAppCore: HackleAppCore) {
        self.hackleAppCore = hackleAppCore
    }

    func isInvocableString(string: String) -> Bool {
        return Invocation.isInvocableString(string: string)
    }

    func invoke(string: String, completionHandler: (String?) -> Void) {
        let result = invoke(string: string)
        completionHandler(result)
    }

    func invoke(string: String) -> String {
        let response: InvokeResponse
        do {
            let invocation = try Invocation(string: string)
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

extension DefaultHackleInvocator {

    private func invoke(command: Invocation.Command, parameters: HackleInvokeParameters, browserProperties: HackleBrowserProperties) throws -> InvokeResponse {
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

fileprivate extension DefaultHackleInvocator {

    private func setUser(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let data = parameters.userAsDictionary() else {
            throw HackleError.error("Valid 'user' parameter must be provided.")
        }
        if let user = User.from(dto: data) {
            hackleAppCore.setUser(user: user, hackleAppContext: hackleAppContext, completion: {})
        }
    }

    private func setUserId(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let userId = parameters.userId() else {
            throw HackleError.error("Valid 'userId' parameter must be provided.")
        }
        hackleAppCore.setUserId(userId: userId, hackleAppContext: hackleAppContext, completion: {})
    }

    private func setDeviceId(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let deviceId = parameters.deviceId() else {
            throw HackleError.error("Valid 'deviceId' parameter must be provided.")
        }
        hackleAppCore.setDeviceId(deviceId: deviceId, hackleAppContext: hackleAppContext, completion: {})
    }

    private func setUserProperty(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let key = parameters.key(),
              let value = parameters.value() else {
            throw HackleError.error("Valid 'key' & 'value' parameter must be provided.")
        }
        let operations = PropertyOperationsBuilder().set(key, value).build()
        
        hackleAppCore.updateUserProperties(operations: operations, hackleAppContext: hackleAppContext, completion: {})
    }

    private func updateUserProperties(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let dto = parameters.propertyOperationDto() else {
            throw HackleError.error("Valid 'operations' parameter must be provided.")
        }
        let operations = PropertyOperations.from(dto: dto)
        hackleAppCore.updateUserProperties(operations: operations, hackleAppContext: hackleAppContext, completion: {})
    }
    
    private func updatePushSubscriptions(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let dto = parameters.subscriptionOperationDto() else {
            throw HackleError.error("Valid 'subscriptions' parameter must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: dto)
        hackleAppCore.updatePushSubscriptions(operations: operations, hackleAppContext: hackleAppContext)
    }
    
    private func updateSmsSubscriptions(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let dto = parameters.subscriptionOperationDto() else {
            throw HackleError.error("Valid 'subscriptions' parameter must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: dto)
        hackleAppCore.updateSmsSubscriptions(operations: operations, hackleAppContext: hackleAppContext)
    }
    
    private func updateKakaoSubscriptions(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let dto = parameters.subscriptionOperationDto() else {
            throw HackleError.error("Valid 'subscriptions' parameter must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: dto)
        hackleAppCore.updateKakaoSubscriptions(operations: operations, hackleAppContext: hackleAppContext)
    }
    
    private func setPhoneNumber(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let phoneNumber = parameters.phoneNumber() else {
            throw HackleError.error("Valid 'phoneNumber' parameter must be provided.")
        }
        hackleAppCore.setPhoneNumber(phoneNumber: phoneNumber, hackleAppContext: hackleAppContext, completion: {})
    }

    private func variation(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws -> String? {
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

    private func variationDetail(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws -> DecisionDto {
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

    private func isFeatureOn(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws -> Bool {
        guard let featureKey = parameters.featureKey() else {
            throw HackleError.error("Valid 'featureKey' parameter must be provided.")
        }
        let result = hackleAppCore.featureFlagDetail(featureKey: featureKey, user: parameters.user(), hackleAppContext: hackleAppContext)
        return result.isOn
    }

    private func featureFlagDetail(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws -> FeatureFlagDecisionDto {
        guard let featureKey = parameters.featureKey() else {
            throw HackleError.error("Valid 'featureKey' parameter must be provided.")
        }
        let result = hackleAppCore.featureFlagDetail(featureKey: featureKey, user: parameters.user(), hackleAppContext: hackleAppContext)
        return result.toDto()
    }

    private func track(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let event = parameters.event() else {
            throw HackleError.error("Valid 'event' parameter must be provided.")
        }
        
        hackleAppCore.track(event: event, user: parameters.user(), hackleAppContext: hackleAppContext)
    }

    private func remoteConfig(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws -> Any {
        guard let key = parameters.key() else {
            throw HackleError.error("Valid 'key' parameter must be provided.")
        }
        guard let valueType = parameters.valueType() else {
            throw HackleError.error("Valid 'valueType' parameter must be provided.")
        }
        
        let user: User? = parameters.userWithUserId()

        switch valueType {
        case "string":
            guard let defaultValue = parameters.defaultStringValue() else {
                throw HackleError.error("Valid 'defaultValue' parameter must be provided.")
            }
            return hackleAppCore
                .remoteConfig(key: key, defaultValue: HackleValue(value: defaultValue),user: user, hackleAppContext: hackleAppContext)
                .value.stringOrNil ?? defaultValue
        case "number":
            guard let defaultValue = parameters.defaultDoubleValue() else {
                throw HackleError.error("Valid 'defaultValue' parameter must be provided.")
            }
            return hackleAppCore
                .remoteConfig(key: key, defaultValue: HackleValue(value: defaultValue),user: user, hackleAppContext: hackleAppContext)
                .value.doubleOrNil ?? defaultValue
        case "boolean":
            guard let defaultValue = parameters.defaultBoolValue() else {
                throw HackleError.error("Valid 'defaultValue' parameter must be provided.")
            }
            return hackleAppCore
                .remoteConfig(key: key, defaultValue: HackleValue(value: defaultValue),user: user, hackleAppContext: hackleAppContext)
                .value.boolOrNil ?? defaultValue
        default:
            throw HackleError.error("Unsupport 'valueType' value provided.")
        }
    }
    
    private func setCurrentScreen(parameters: HackleInvokeParameters, hackleAppContext: HackleAppContext) throws {
        guard let screenName = parameters.screenName() else {
            throw HackleError.error("Valid 'screenName' parameter must be provided.")
        }
        guard let className = parameters.className() else {
            throw HackleError.error("Valid 'className' parameter must be provided.")
        }
        
        hackleAppCore.setCurrentScreen(screen: Screen(name: screenName, className: className), hackleAppContext: hackleAppContext)
    }
}

import Foundation

protocol InvocationHandlerFactory {
    func get(command: InvocationCommand) throws -> any InvocationHandler
}

class DefaultInvocationHandlerFactory: InvocationHandlerFactory {
    private let core: HackleAppCore

    private var handlers: [InvocationCommand: any InvocationHandler] = [:]

    init(core: HackleAppCore) {
        self.core = core
        for command in InvocationCommand.allCases {
            handlers[command] = create(command: command)
        }
    }

    func get(command: InvocationCommand) throws -> any InvocationHandler {
        guard let handler = handlers[command] else {
            throw HackleError.error("Not found InvocationHandler [\(command)]")
        }
        return handler
    }

    private func create(command: InvocationCommand) -> any InvocationHandler {
        switch command {
            case .getSessionId:
                return GetSessionIdInvocationHandler(core: core)
            case .getUser:
                return GetUserInvocationHandler(core: core)
            case .setUser:
                return SetUserInvocationHandler(core: core)
            case .resetUser:
                return ResetUserInvocationHandler(core: core)
            case .setUserId:
                return SetUserIdInvocationHandler(core: core)
            case .setDeviceId:
                return SetDeviceIdInvocationHandler(core: core)
            case .setUserProperty:
                return SetUserPropertyInvocationHandler(core: core)
            case .updateUserProperties:
                return UpdateUserPropertiesInvocationHandler(core: core)
            case .setPhoneNumber:
                return SetPhoneNumberInvocationHandler(core: core)
            case .unsetPhoneNumber:
                return UnsetPhoneNumberInvocationHandler(core: core)
            case .updatePushSubscriptions:
                return UpdatePushSubscriptionsInvocationHandler(core: core)
            case .updateSmsSubscriptions:
                return UpdateSmsSubscriptionsInvocationHandler(core: core)
            case .updateKakaoSubscriptions:
                return UpdateKakaoSubscriptionsInvocationHandler(core: core)
            case .variation:
                return VariationInvocationHandler(core: core)
            case .variationDetail:
                return VariationDetailInvocationHandler(core: core)
            case .isFeatureOn:
                return IsFeatureOnInvocationHandler(core: core)
            case .featureFlagDetail:
                return FeatureFlagDetailInvocationHandler(core: core)
            case .remoteConfig:
                return RemoteConfigInvocationHandler(core: core)
            case .track:
                return TrackInvocationHandler(core: core)
            case .setCurrentScreen:
                return SetCurrentScreenInvocationHandler(core: core)
            case .setOptOutTracking:
                return SetOptOutTrackingInvocationHandler(core: core)
            case .showUserExplorer:
                return ShowUserExplorerInvocationHandler(core: core)
            case .hideUserExplorer:
                return HideUserExplorerInvocationHandler(core: core)
        }
    }
}

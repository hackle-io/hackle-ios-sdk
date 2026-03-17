import Foundation

// MARK: - Session

class GetSessionIdInvocationHandler: InvocationHandler {
    typealias T = String

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<String> {
        return .success(data: core.sessionId)
    }
}

// MARK: - User

class GetUserInvocationHandler: InvocationHandler {
    typealias T = UserDto

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<UserDto> {
        return .success(data: core.user.toDto())
    }
}

class SetUserInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let data = request.parameters.userAsDictionary() else {
            throw HackleError.error("parameters.user must be provided.")
        }
        let user = User.from(dto: data)
        core.setUser(user: user, hackleAppContext: request.appContext, completion: {})
        return .success()
    }
}

class ResetUserInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        core.resetUser(hackleAppContext: request.appContext, completion: {})
        return .success()
    }
}

// MARK: - UserIdentifiers

class SetUserIdInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let userId = request.parameters.userId() else {
            throw HackleError.error("parameters.userId must be provided.")
        }
        core.setUserId(userId: userId, hackleAppContext: request.appContext, completion: {})
        return .success()
    }
}

class SetDeviceIdInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let deviceId = request.parameters.deviceId() else {
            throw HackleError.error("parameters.deviceId must be provided.")
        }
        core.setDeviceId(deviceId: deviceId, hackleAppContext: request.appContext, completion: {})
        return .success()
    }
}

// MARK: - UserProperties

class SetUserPropertyInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let key = request.parameters.key(),
              let value = request.parameters.value()
        else {
            throw HackleError.error("parameters.key, parameters.value must be provided.")
        }

        let operations = PropertyOperations.builder()
            .set(key, value)
            .build()

        core.updateUserProperties(operations: operations, hackleAppContext: request.appContext, completion: {})
        return .success()
    }
}

class UpdateUserPropertiesInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let dto = request.parameters.propertyOperationDto() else {
            throw HackleError.error("parameters.operations must be provided.")
        }
        let operations = PropertyOperations.from(dto: dto)
        core.updateUserProperties(operations: operations, hackleAppContext: request.appContext, completion: {})
        return .success()
    }
}

// MARK: - User - PhoneNumber

class SetPhoneNumberInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let phoneNumber = request.parameters.phoneNumber() else {
            throw HackleError.error("parameters.phoneNumber must be provided.")
        }

        core.setPhoneNumber(phoneNumber: phoneNumber, hackleAppContext: request.appContext, completion: {})
        return .success()
    }
}

class UnsetPhoneNumberInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        core.unsetPhoneNumber(hackleAppContext: request.appContext, completion: {})
        return .success()
    }
}

// MARK: User - Subscriptions

protocol SubscriptionsInvocationHandler: InvocationHandler where T == Void {
    var core: HackleAppCore { get }
    func update(core: HackleAppCore, operations: HackleSubscriptionOperations, context: HackleAppContext)
}

extension SubscriptionsInvocationHandler {
    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let dto = request.parameters.subscriptionOperationDto() else {
            throw HackleError.error("parameters.subscriptions must be provided.")
        }
        let operations = HackleSubscriptionOperations.from(dto: dto)
        update(core: core, operations: operations, context: request.appContext)
        return .success()
    }
}

class UpdatePushSubscriptionsInvocationHandler: SubscriptionsInvocationHandler {
    let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func update(core: HackleAppCore, operations: HackleSubscriptionOperations, context: HackleAppContext) {
        core.updatePushSubscriptions(operations: operations, hackleAppContext: context)
    }
}

class UpdateSmsSubscriptionsInvocationHandler: SubscriptionsInvocationHandler {
    let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func update(core: HackleAppCore, operations: HackleSubscriptionOperations, context: HackleAppContext) {
        core.updateSmsSubscriptions(operations: operations, hackleAppContext: context)
    }
}

class UpdateKakaoSubscriptionsInvocationHandler: SubscriptionsInvocationHandler {
    let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func update(core: HackleAppCore, operations: HackleSubscriptionOperations, context: HackleAppContext) {
        core.updateKakaoSubscriptions(operations: operations, hackleAppContext: context)
    }
}

// MARK: - AbTest

protocol AbTestInvocationHandler: InvocationHandler {
    var core: HackleAppCore { get }
    func transform(decision: Decision) -> T
}

extension AbTestInvocationHandler {
    func invoke(request: InvocationRequest) throws -> InvocationResponse<T> {
        guard let experimentKey = request.parameters.experimentKey() else {
            throw HackleError.error("parameters.experimentKey must be provided.")
        }
        let defaultVariation = request.parameters.defaultVariation()
        let user = request.parameters.user()
        let decision = core.variationDetail(
            experimentKey: experimentKey,
            user: user,
            defaultVariation: defaultVariation,
            hackleAppContext: request.appContext
        )
        let data = transform(decision: decision)
        return .success(data: data)
    }
}

class VariationInvocationHandler: AbTestInvocationHandler {
    typealias T = String

    let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func transform(decision: Decision) -> String {
        return decision.variation
    }
}

class VariationDetailInvocationHandler: AbTestInvocationHandler {
    typealias T = DecisionDto

    let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func transform(decision: Decision) -> DecisionDto {
        return decision.toDto()
    }
}

// MARK: - FeatureFlag

protocol FeatureFlagInvocationHandler: InvocationHandler {
    var core: HackleAppCore { get }
    func transform(decision: FeatureFlagDecision) -> T
}

extension FeatureFlagInvocationHandler {
    func invoke(request: InvocationRequest) throws -> InvocationResponse<T> {
        guard let featureKey = request.parameters.featureKey() else {
            throw HackleError.error("parameters.featureKey must be provided.")
        }

        let user = request.parameters.user()
        let decision = core.featureFlagDetail(featureKey: featureKey, user: user, hackleAppContext: request.appContext)
        let data = transform(decision: decision)
        return .success(data: data)
    }
}

class IsFeatureOnInvocationHandler: FeatureFlagInvocationHandler {
    typealias T = Bool

    let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func transform(decision: FeatureFlagDecision) -> Bool {
        return decision.isOn
    }
}

class FeatureFlagDetailInvocationHandler: FeatureFlagInvocationHandler {
    typealias T = FeatureFlagDecisionDto

    let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func transform(decision: FeatureFlagDecision) -> FeatureFlagDecisionDto {
        return decision.toDto()
    }
}

// MARK: - RemoteConfig

class RemoteConfigInvocationHandler: InvocationHandler {
    typealias T = Any

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Any> {
        guard let valueType = request.parameters.valueType() else {
            throw HackleError.error("parameters.valueType must be provided.")
        }
        switch valueType {
        case "string":
            return try decide(request: request, defaultValue: { $0.parameters.defaultStringValue() }, resultValue: { $0.stringOrNil })
        case "number":
            return try decide(request: request, defaultValue: { $0.parameters.defaultDoubleValue() }, resultValue: { $0.doubleOrNil })
        case "boolean":
            return try decide(request: request, defaultValue: { $0.parameters.defaultBoolValue() }, resultValue: { $0.boolOrNil })
        default:
            throw HackleError.error("Unsupported valueType (\(valueType)")
        }
    }

    private func decide<V>(request: InvocationRequest, defaultValue: (InvocationRequest) -> V?, resultValue: (HackleValue) -> V?) throws -> InvocationResponse<V> {
        guard let key = request.parameters.key() else {
            throw HackleError.error("parameters.key must be provided.")
        }
        guard let defaultValue = defaultValue(request) else {
            throw HackleError.error("parameters.defaultValue must be provided.")
        }
        let user = request.parameters.user()
        let decision = core.remoteConfig(key: key, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: request.appContext)
        let resultValue = resultValue(decision.value)
        let value = resultValue ?? defaultValue
        return .success(data: value)
    }
}

// MARK: - Event

class TrackInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let event = request.parameters.event() else {
            throw HackleError.error("parameters.event must be provided.")
        }
        let user = request.parameters.user()
        core.track(event: event, user: user, hackleAppContext: request.appContext)
        return .success()
    }
}

// MARK: - InAppMessage

class GetCurrentInAppMessageViewInvocationHandler: InvocationHandler {
    typealias T = HackleInAppMessageViewDto

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<HackleInAppMessageViewDto> {
        guard let view = MainActor.assumeIsolated({ core.currentInAppMessageView }) else {
            return .success()
        }
        let viewDto = view.toDto()
        return .success(data: viewDto)
    }
}

class CloseInAppMessageViewInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let viewId = request.parameters.viewId() else {
            throw HackleError.error("parameters.viewId must be provided.")
        }

        MainActor.assumeIsolated {
            guard let view = core.getInAppMessageView(viewId: viewId) else {
                return
            }
            view.dismiss()
        }
        return .success()
    }
}

class HandleInAppMessageViewInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        let invocationDto: HandleInAppMessageViewInvocationDto = try request.parameters()
        try MainActor.assumeIsolated {
            guard let view = core.getInAppMessageView(viewId: invocationDto.viewId) else {
                return
            }
            let event = try viewEvent(view: view, dto: invocationDto.event)
            let handleTypes: [InAppMessageViewEventHandleType] = try Enums.parseAll(invocationDto.handleTypes)
            view.handle(event: event, types: handleTypes)
        }
        return .success()
    }

    @MainActor
    private func viewEvent(view: InAppMessageView, dto: InAppMessageViewEventDto) throws -> InAppMessageViewEvent {
        let eventType: InAppMessageViewEventType = try Enums.parse(rawValue: dto.type)
        switch eventType {
        case .action:
            return try actionEvent(view: view, dto: dto)
        case .impression, .close, .imageImpression:
            throw HackleError.error("Unsupported InAppMessageViewEventType [\(eventType)]")
        }
    }

    @MainActor
    private func actionEvent(view: InAppMessageView, dto: InAppMessageViewEventDto) throws -> InAppMessageViewActionEvent {
        guard let action = dto.action else {
            throw HackleError.error("action must be provided.")
        }
        guard let element = dto.element else {
            throw HackleError.error("element must be provided.")
        }
        return try .action(
            timestamp: view.clock.now(),
            action: action.toAction(),
            area: element.area.map { try Enums.parse(rawValue: $0) },
            elementId: element.elementId
        )
    }
}

// MARK: - Screen

class SetCurrentScreenInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let screenName = request.parameters.screenName() else {
            throw HackleError.error("parameter.screenName must be provided.")
        }
        guard let className = request.parameters.className() else {
            throw HackleError.error("parameter.className must be provided.")
        }
        let screen = Screen.builder(name: screenName, className: className).build()
        core.setCurrentScreen(screen: screen, hackleAppContext: request.appContext)
        return .success()
    }
}

// MARK: - Configuration

class SetOptOutTrackingInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        guard let optOut = request.parameters.optOut() else {
            throw HackleError.error("parameter.optOut must be provided.")
        }
        core.setOptOutTracking(optOut: optOut)
        return .success()
    }
}

class IsOptOutTrackingInvocationHandler: InvocationHandler {
    typealias T = Bool

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Bool> {
        return .success(data: core.isOptOutTracking)
    }
}

// MARK: - DevTools

class ShowUserExplorerInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        core.showUserExplorer()
        return .success()
    }
}

class HideUserExplorerInvocationHandler: InvocationHandler {
    typealias T = Void

    private let core: HackleAppCore
    init(core: HackleAppCore) {
        self.core = core
    }

    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        core.hideUserExplorer()
        return .success()
    }
}

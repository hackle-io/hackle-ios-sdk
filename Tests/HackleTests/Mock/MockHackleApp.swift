import Foundation
@testable import Hackle
import MockingKit

class MockHackleAppCore: Mock, HackleAppCore {
    var sdk: Sdk
    var sessionId: String
    var deviceId: String
    var user: User
    var hackleAppContext: HackleAppContext?
    var currentInAppMessageView: InAppMessageView?
    
    init(
        sdkKey: String = "",
        sessonId: String = "",
        deviceId: String = "",
        user: User = HackleUserBuilder().build()
    ) {
        self.sdk = Sdk.of(sdkKey: sdkKey, config: HackleConfig.DEFAULT)
        self.sessionId = sessonId
        self.deviceId = deviceId
        self.user = user
        super.init()
        every(setUserRef).answers { _ in Task {} }
        every(setUserIdRef).answers { _ in Task {} }
        every(setDeviceIdRef).answers { _ in Task {} }
        every(resetUserRef).answers { _ in Task {} }
        every(fetchRef).answers { _ in Task {} }
    }

    lazy var getInAppMessageViewRef = MockFunction(self, getInAppMessageView)
    func getInAppMessageView(viewId: String) -> InAppMessageView? {
        call(getInAppMessageViewRef, args: viewId)
    }

    lazy var showUserExplorerRef = MockFunction(self, showUserExplorer)
    func showUserExplorer() {
        call(showUserExplorerRef, args: ())
    }

    lazy var hideUserExplorerRef = MockFunction(self, hideUserExplorer)
    func hideUserExplorer() {
        call(hideUserExplorerRef, args: ())
    }

    lazy var setDeviceIdRef = MockFunction(self, setDeviceId)
    func setDeviceId(deviceId: String, hackleAppContext: HackleAppContext) -> Task<Void, Never> {
        self.hackleAppContext = hackleAppContext
        return call(setDeviceIdRef, args: (deviceId, hackleAppContext))
    }

    lazy var setUserRef = MockFunction(self, setUser)
    func setUser(user: User, hackleAppContext: HackleAppContext) -> Task<Void, Never> {
        self.hackleAppContext = hackleAppContext
        return call(setUserRef, args: (user, hackleAppContext))
    }

    lazy var setUserIdRef = MockFunction(self, setUserId)
    func setUserId(userId: String?, hackleAppContext: HackleAppContext) -> Task<Void, Never> {
        self.hackleAppContext = hackleAppContext
        return call(setUserIdRef, args: (userId, hackleAppContext))
    }

    lazy var updateUserPropertiesRef = MockFunction(self, updateUserProperties)
    func updateUserProperties(operations: PropertyOperations, hackleAppContext: HackleAppContext) {
        self.hackleAppContext = hackleAppContext
        call(updateUserPropertiesRef, args: (operations, hackleAppContext))
    }
    
    lazy var updatePushSubscriptionsRef = MockFunction(self, updatePushSubscriptions as (HackleSubscriptionOperations, HackleAppContext) -> ())
    func updatePushSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        self.hackleAppContext = hackleAppContext
        call(updatePushSubscriptionsRef, args: (operations, hackleAppContext))
    }
    
    lazy var updateSmsSubscriptionsRef = MockFunction(self, updateSmsSubscriptions as (HackleSubscriptionOperations, HackleAppContext) -> ())
    func updateSmsSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        self.hackleAppContext = hackleAppContext
        call(updateSmsSubscriptionsRef, args: (operations, hackleAppContext))
    }
    
    lazy var updateKakaoSubscriptionsRef = MockFunction(self, updateKakaoSubscriptions as (HackleSubscriptionOperations, HackleAppContext) -> ())
    func updateKakaoSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        self.hackleAppContext = hackleAppContext
        call(updateKakaoSubscriptionsRef, args: (operations, hackleAppContext))
    }
    
    lazy var resetUserRef = MockFunction(self, resetUser)
    func resetUser(hackleAppContext: HackleAppContext) -> Task<Void, Never> {
        self.hackleAppContext = hackleAppContext
        return call(resetUserRef, args: hackleAppContext)
    }

    lazy var setPhoneNumberRef = MockFunction(self, setPhoneNumber)
    func setPhoneNumber(phoneNumber: String, hackleAppContext: HackleAppContext) {
        self.hackleAppContext = hackleAppContext
        call(setPhoneNumberRef, args: (phoneNumber, hackleAppContext))
    }

    lazy var unsetPhoneNumberRef = MockFunction(self, unsetPhoneNumber)
    func unsetPhoneNumber(hackleAppContext: HackleAppContext) {
        self.hackleAppContext = hackleAppContext
        call(unsetPhoneNumberRef, args: hackleAppContext)
    }
    
    lazy var variationDetailRef = MockFunction(self, variationDetail as (Int, User?, String, HackleAppContext) -> Decision)
    func variationDetail(experimentKey: Int, user: User?, defaultVariation: String, hackleAppContext: HackleAppContext) -> Decision {
        self.hackleAppContext = hackleAppContext
        return call(variationDetailRef, args: (experimentKey, user, defaultVariation, hackleAppContext))
    }
    
    lazy var featureFlagDetailRef = MockFunction(self, featureFlagDetail as (Int, User?, HackleAppContext) -> FeatureFlagDecision)
    func featureFlagDetail(featureKey: Int, user: User?, hackleAppContext: HackleAppContext) -> FeatureFlagDecision {
        self.hackleAppContext = hackleAppContext
        return call(featureFlagDetailRef, args: (featureKey, user, hackleAppContext))
    }
    
    lazy var trackRef = MockFunction(self, track as (Event, User?, HackleAppContext) -> ())
    func track(event: Event, user: User?, hackleAppContext: HackleAppContext) {
        self.hackleAppContext = hackleAppContext
        call(trackRef, args: (event, user, hackleAppContext))
    }
    
    lazy var remoteConfigRef = MockFunction(self, remoteConfig as (String, HackleValue, User?, HackleAppContext) -> RemoteConfigDecision)
    func remoteConfig(key: String, defaultValue: HackleValue, user: User?, hackleAppContext: HackleAppContext) -> RemoteConfigDecision {
        self.hackleAppContext = hackleAppContext
        return call(remoteConfigRef, args: (key, defaultValue, user, hackleAppContext))
    }
    
    lazy var setCurrentScreenRef = MockFunction(self, setCurrentScreen as (Screen, HackleAppContext) -> ())
    func setCurrentScreen(screen: Screen, hackleAppContext: HackleAppContext) {
        self.hackleAppContext = hackleAppContext
        call(setCurrentScreenRef, args: (screen, hackleAppContext))
    }
    
    lazy var fetchRef = MockFunction(self, fetch)
    func fetch() -> Task<Void, Never> {
        call(fetchRef, args: ())
    }

    func initialize(user: User?, completion: @escaping () -> ()) {
        fatalError("NOT IMPLEMENTED")
    }
    
    func allVariationDetails(user: User?) -> [Int: Decision] {
        fatalError("NOT IMPLEMENTED")
    }
    
    func allVariationDetails(user: User?, hackleAppContext: HackleAppContext) -> [Int: Decision] {
        fatalError("NOT IMPLEMENTED")
    }
    
    func setPushToken(deviceToken: Data) {
        fatalError("NOT IMPLEMENTED")
    }
    
    func setInAppMessageDelegate(_ delegate: (any HackleInAppMessageDelegate)?) {
        fatalError("NOT IMPLEMENTED")
    }

    var isOptOutTracking: Bool = false

    lazy var setOptOutTrackingRef = MockFunction(self, setOptOutTracking)
    func setOptOutTracking(optOut: Bool) {
        call(setOptOutTrackingRef, args: optOut)
    }
}

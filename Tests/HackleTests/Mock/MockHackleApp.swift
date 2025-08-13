import Foundation
import Mockery
@testable import Hackle

class MockHackleAppCore : Mock, HackleAppCore {
    
    var sdk: Sdk
    var sessionId: String
    var deviceId: String
    var user: User
    var _remoteConfig: HackleRemoteConfig

    init(
        sdkKey: String = "",
        sessonId: String = "",
        deviceId: String = "",
        user: User = HackleUserBuilder().build(),
        remoteConfig: HackleRemoteConfig = MockRemoteConfig()
    ) {
        self.sdk = Sdk.of(sdkKey: sdkKey, config: HackleConfig.DEFAULT)
        self.sessionId = sessonId
        self.deviceId = deviceId
        self.user = user
        self._remoteConfig = remoteConfig
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
    func setDeviceId(deviceId: String, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        call(setDeviceIdRef, args: (deviceId, hackleAppContext, completion))
    }
    
    lazy var setUserRef = MockFunction(self, setUser)
    func setUser(user: User, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        call(setUserRef, args: (user, hackleAppContext, completion))
    }
    
    lazy var setUserIdRef = MockFunction(self, setUserId)
    func setUserId(userId: String?, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        call(setUserIdRef, args: (userId, hackleAppContext, completion))
    }
    
    lazy var updateUserPropertiesRef = MockFunction(self, updateUserProperties)
    func updateUserProperties(operations: PropertyOperations, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        call(updateUserPropertiesRef, args: (operations, hackleAppContext, completion))
    }
    
    lazy var updatePushSubscriptionsRef = MockFunction(self, updatePushSubscriptions as (HackleSubscriptionOperations, HackleAppContext) -> Void)
    func updatePushSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        call(updatePushSubscriptionsRef, args: (operations, hackleAppContext))
    }
    
    lazy var updateSmsSubscriptionsRef = MockFunction(self, updateSmsSubscriptions as (HackleSubscriptionOperations, HackleAppContext) -> Void)
    func updateSmsSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        call(updateSmsSubscriptionsRef, args: (operations, hackleAppContext))
    }
    
    lazy var updateKakaoSubscriptionsRef = MockFunction(self, updateKakaoSubscriptions as (HackleSubscriptionOperations, HackleAppContext) -> Void)
    func updateKakaoSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        call(updateKakaoSubscriptionsRef, args: (operations, hackleAppContext))
    }
    
    lazy var resetUserRef = MockFunction(self, resetUser)
    func resetUser(hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        call(resetUserRef, args: (hackleAppContext, completion))
    }
    
    lazy var setPhoneNumberRef = MockFunction(self, setPhoneNumber)
    func setPhoneNumber(phoneNumber: String, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        call(setPhoneNumberRef, args: (phoneNumber, hackleAppContext, completion))
    }
    
    lazy var unsetPhoneNumberRef = MockFunction(self, unsetPhoneNumber)
    func unsetPhoneNumber(hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        call(unsetPhoneNumberRef, args: (hackleAppContext, completion))
    }
    
    lazy var variationDetailRef = MockFunction(self, variationDetail as (Int, User?, String, HackleAppContext) -> Decision)
    func variationDetail(experimentKey: Int, user: User?, defaultVariation: String, hackleAppContext: HackleAppContext) -> Decision {
        call(variationDetailRef, args: (experimentKey, user, defaultVariation, hackleAppContext))
    }
    
    lazy var featureFlagDetailRef = MockFunction(self, featureFlagDetail as (Int, User?, HackleAppContext) -> FeatureFlagDecision)
    func featureFlagDetail(featureKey: Int, user: User?, hackleAppContext: HackleAppContext) -> FeatureFlagDecision {
        call(featureFlagDetailRef, args: (featureKey, user, hackleAppContext))
    }
    
    lazy var trackRef = MockFunction(self, track as (Event, User?, HackleAppContext) -> Void)
    func track(event: Event, user: User?, hackleAppContext: HackleAppContext) {
        call(trackRef, args: (event, user, hackleAppContext))
    }
    
    lazy var remoteConfigRef = MockFunction(self, remoteConfig as (User?, HackleAppContext) -> HackleRemoteConfig)
    func remoteConfig(user: User?, hackleAppContext: HackleAppContext) -> any HackleRemoteConfig {
        every(remoteConfigRef).returns(self._remoteConfig)
        return call(remoteConfigRef, args: (user, hackleAppContext))
    }
    
    lazy var setCurrentScreenRef = MockFunction(self, setCurrentScreen as (Screen, HackleAppContext) -> Void)
    func setCurrentScreen(screen: Screen, hackleAppContext: HackleAppContext) {
        call(setCurrentScreenRef, args: (screen, hackleAppContext))
    }
    
    lazy var fetchRef = MockFunction(self, fetch)
    func fetch(completion: @escaping () -> ()) {
        call(fetchRef, args: completion)
    }

    func initialize(user: User?, completion: @escaping () -> ()) {
        fatalError("NOT IMPLEMENTED")
    }
    
    func allVariationDetails(user: User?) -> [Int : Decision] {
        fatalError("NOT IMPLEMENTED")
    }
    
    func allVariationDetails(user: User?, hackleAppContext: HackleAppContext) -> [Int : Decision] {
        fatalError("NOT IMPLEMENTED")
    }
    
    func setPushToken(deviceToken: Data) {
        fatalError("NOT IMPLEMENTED")
    }
    
    func setInAppMessageDelegate(_ delegate: (any HackleInAppMessageDelegate)?) {
        fatalError("NOT IMPLEMENTED")
    }
}

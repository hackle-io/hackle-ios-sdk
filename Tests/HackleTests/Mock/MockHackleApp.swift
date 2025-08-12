import Foundation
import Mockery
@testable import Hackle

class MockHackleAppCore : Mock, HackleAppCoreProtocol {
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
    func setDeviceId(deviceId: String, completion: @escaping () -> ()) {
        call(setDeviceIdRef, args: (deviceId, completion))
    }
    
    lazy var setUserRef = MockFunction(self, setUser)
    func setUser(user: User, completion: @escaping () -> ()) {
        call(setUserRef, args: (user, completion))
    }
    
    lazy var setUserIdRef = MockFunction(self, setUserId)
    func setUserId(userId: String?, completion: @escaping () -> ()) {
        call(setUserIdRef, args: (userId, completion))
    }
    
    lazy var updateUserPropertiesRef = MockFunction(self, updateUserProperties)
    func updateUserProperties(operations: PropertyOperations, completion: @escaping () -> ()) {
        call(updateUserPropertiesRef, args: (operations, completion))
    }
    
    lazy var updatePushSubscriptionsRef = MockFunction(self, updatePushSubscriptions as (HackleSubscriptionOperations) -> Void)
    func updatePushSubscriptions(operations: HackleSubscriptionOperations) {
        call(updatePushSubscriptionsRef, args: (operations))
    }
    
    lazy var updateSmsSubscriptionsRef = MockFunction(self, updateSmsSubscriptions as (HackleSubscriptionOperations) -> Void)
    func updateSmsSubscriptions(operations: HackleSubscriptionOperations) {
        call(updateSmsSubscriptionsRef, args: (operations))
    }
    
    lazy var updateKakaoSubscriptionsRef = MockFunction(self, updateKakaoSubscriptions as (HackleSubscriptionOperations) -> Void)
    func updateKakaoSubscriptions(operations: HackleSubscriptionOperations) {
        call(updateKakaoSubscriptionsRef, args: (operations))
    }
    
    lazy var resetUserRef = MockFunction(self, resetUser)
    func resetUser(completion: @escaping () -> ()) {
        call(resetUserRef, args: completion)
    }
    
    lazy var setPhoneNumberRef = MockFunction(self, setPhoneNumber)
    func setPhoneNumber(phoneNumber: String, completion: @escaping () -> ()) {
        call(setPhoneNumberRef, args: (phoneNumber, completion))
    }
    
    lazy var unsetPhoneNumberRef = MockFunction(self, unsetPhoneNumber)
    func unsetPhoneNumber(completion: @escaping () -> ()) {
        call(unsetPhoneNumberRef, args: completion)
    }
    
    lazy var variationDetailRef = MockFunction(self, variationDetail as (Int, User?, String) -> Decision)
    func variationDetail(experimentKey: Int, user: User?, defaultVariation: String) -> Decision {
        call(variationDetailRef, args: (experimentKey, user, defaultVariation))
    }
    
    lazy var featureFlagDetailRef = MockFunction(self, featureFlagDetail as (Int, User?) -> FeatureFlagDecision)
    func featureFlagDetail(featureKey: Int, user: User?) -> FeatureFlagDecision {
        call(featureFlagDetailRef, args: (featureKey, user))
    }
    
    lazy var trackRef = MockFunction(self, track as (Event, User?) -> Void)
    func track(event: Event, user: User?) {
        call(trackRef, args: (event, user))
    }
    
    lazy var remoteConfigRef = MockFunction(self, remoteConfig as (User?) -> HackleRemoteConfig)
    func remoteConfig(user: User?) -> any HackleRemoteConfig {
        every(remoteConfigRef).returns(self._remoteConfig)
        return call(remoteConfigRef, args: (user))
    }
    
    lazy var setCurrentScreenRef = MockFunction(self, setCurrentScreen as (Screen) -> Void)
    func setCurrentScreen(screen: Screen) {
        call(setCurrentScreenRef, args: (screen))
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
}

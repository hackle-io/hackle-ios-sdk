import Foundation
import Mockery
@testable import Hackle

class MockHackleApp : Mock, HackleAppProtocol {
    
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
    
    lazy var setDeviceIdRef = MockFunction(self, setDeviceId)
    func setDeviceId(deviceId: String) {
        call(setDeviceIdRef, args: deviceId)
    }

    lazy var showUserExplorerRef = MockFunction(self, showUserExplorer)
    func showUserExplorer() {
        call(showUserExplorerRef, args: ())
    }

    lazy var hideUserExplorerRef = MockFunction(self, hideUserExplorer)
    func hideUserExplorer() {
        call(hideUserExplorerRef, args: ())
    }

    lazy var setUserRef = MockFunction(self, setUser)
    func setUser(user: User) {
        call(setUserRef, args: user)
    }

    lazy var setUserIdRef = MockFunction(self, setUserId)
    func setUserId(userId: String?) {
        call(setUserIdRef, args: userId)
    }

    lazy var setUserPropertyRef = MockFunction(self, setUserProperty)
    func setUserProperty(key: String, value: Any?) {
        call(setUserPropertyRef, args: (key, value))
    }

    lazy var updateUserPropertiesRef = MockFunction(self, updateUserProperties)
    func updateUserProperties(operations: PropertyOperations) {
        call(updateUserPropertiesRef, args: operations)
    }

    lazy var resetUserRef = MockFunction(self, resetUser)
    func resetUser() {
        call(resetUserRef, args: ())
    }
    
    lazy var setPhoneNumberRef = MockFunction(self, setPhoneNumber)
    func setPhoneNumber(phoneNumber: String) {
        call(setPhoneNumberRef, args: (phoneNumber))
    }
    
    lazy var unsetPhoneNumberRef = MockFunction(self, unsetPhoneNumber)
    func unsetPhoneNumber() {
        call(unsetPhoneNumberRef, args: ())
    }

    lazy var variationRef = MockFunction(self, variation as (Int, String) -> String)
    func variation(experimentKey: Int, defaultVariation: String) -> String {
        return call(variationRef, args: (experimentKey, defaultVariation))
    }
    
    lazy var variationWithUserIdRef = MockFunction(self, variation as (Int, String, String) -> String)
    func variation(experimentKey: Int, userId: String, defaultVariation: String) -> String {
        return call(variationWithUserIdRef, args: (experimentKey, userId, defaultVariation))
    }
    
    lazy var variationWithUserRef = MockFunction(self, variation as (Int, User, String) -> String)
    func variation(experimentKey: Int, user: User, defaultVariation: String) -> String {
        return call(variationWithUserRef, args: (experimentKey, user, defaultVariation))
    }
    
    lazy var variationDetailRef = MockFunction(self, variationDetail as (Int, String) -> Decision)
    func variationDetail(experimentKey: Int, defaultVariation: String) -> Decision {
        return call(variationDetailRef, args: (experimentKey, defaultVariation))
    }
    
    lazy var variationDetailWithUserIdRef = MockFunction(self, variationDetail as (Int, String, String) -> Decision)
    func variationDetail(experimentKey: Int, userId: String, defaultVariation: String) -> Decision {
        return call(variationDetailWithUserIdRef, args: (experimentKey, userId, defaultVariation))
    }

    lazy var variationDetailWithUserRef = MockFunction(self, variationDetail as (Int, User, String) -> Decision)
    func variationDetail(experimentKey: Int, user: User, defaultVariation: String) -> Decision {
        return call(variationDetailWithUserRef, args: (experimentKey, user, defaultVariation))
    }

    lazy var isFeatureOnRef = MockFunction(self, isFeatureOn as (Int) -> Bool)
    func isFeatureOn(featureKey: Int) -> Bool {
        return call(isFeatureOnRef, args: (featureKey))
    }
    
    lazy var isFeatureOnWithUserIdRef = MockFunction(self, isFeatureOn as (Int, String) -> Bool)
    func isFeatureOn(featureKey: Int, userId: String) -> Bool {
        return call(isFeatureOnWithUserIdRef, args: (featureKey, userId))
    }

    lazy var isFeatureOnWithUserRef = MockFunction(self, isFeatureOn as (Int, User) -> Bool)
    func isFeatureOn(featureKey: Int, user: User) -> Bool {
        return call(isFeatureOnWithUserRef, args: (featureKey, user))
    }

    lazy var featureFlagDetailRef = MockFunction(self, featureFlagDetail as (Int) -> FeatureFlagDecision)
    func featureFlagDetail(featureKey: Int) -> FeatureFlagDecision {
        return call(featureFlagDetailRef, args: (featureKey))
    }
    
    lazy var featureFlagDetailWithUserIdRef = MockFunction(self, featureFlagDetail as (Int, String) -> FeatureFlagDecision)
    func featureFlagDetail(featureKey: Int, userId: String) -> FeatureFlagDecision {
        return call(featureFlagDetailWithUserIdRef, args: (featureKey, userId))
    }

    lazy var featureFlagDetailWithUserRef = MockFunction(self, featureFlagDetail as (Int, User) -> FeatureFlagDecision)
    func featureFlagDetail(featureKey: Int, user: User) -> FeatureFlagDecision {
        return call(featureFlagDetailWithUserRef, args: (featureKey, user))
    }

    lazy var trackWithEventKeyRef = MockFunction(self, track as (String) -> Void)
    func track(eventKey: String) {
        call(trackWithEventKeyRef, args: (eventKey))
    }
    
    lazy var trackWithEventKeyUserIdRef = MockFunction(self, track as (String, String) -> Void)
    func track(eventKey: String, userId: String) {
        call(trackWithEventKeyUserIdRef, args: (eventKey, userId))
    }

    lazy var trackWithEventKeyUserRef = MockFunction(self, track as (String, User) -> Void)
    func track(eventKey: String, user: User) {
        call(trackWithEventKeyUserRef, args: (eventKey, user))
    }

    lazy var trackWithEventRef = MockFunction(self, track as (Event) -> Void)
    func track(event: Event) {
        call(trackWithEventRef, args: (event))
    }
    
    lazy var trackWithEventUserIdRef = MockFunction(self, track as (Event, String) -> Void)
    func track(event: Event, userId: String) {
        call(trackWithEventUserIdRef, args: (event, userId))
    }

    lazy var trackWithEventUserRef = MockFunction(self, track as (Event, User) -> Void)
    func track(event: Event, user: User) {
        call(trackWithEventUserRef, args: (event, user))
    }

    lazy var remoteConfigRef = MockFunction(self, remoteConfig as () -> HackleRemoteConfig)
    func remoteConfig() -> HackleRemoteConfig {
        every(remoteConfigRef).returns(self._remoteConfig)
        return call(remoteConfigRef, args: ())
    }
    
    lazy var remoteConfigWithUserRef = MockFunction(self, remoteConfig as (User) -> HackleRemoteConfig)
    func remoteConfig(user: User) -> HackleRemoteConfig {
        every(remoteConfigWithUserRef).returns(self._remoteConfig)
        return call(remoteConfigWithUserRef, args: (user))
    }
    
    func allVariationDetails() -> [Int : Decision] {
        fatalError("NOT IMPLEMENTED")
    }

    func allVariationDetails(user: User) -> [Int : Decision] {
        fatalError("NOT IMPLEMENTED")
    }
}

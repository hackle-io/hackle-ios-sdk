import Foundation

enum InvocationCommand: String, CaseIterable {
    // Session
    case getSessionId
    
    // User
    case getUser
    case setUser
    case resetUser
    
    // UserIdentifiers
    case setUserId
    case setDeviceId
    
    // UserProperties
    case setUserProperty
    case updateUserProperties
    
    // User - Phone
    case setPhoneNumber
    case unsetPhoneNumber
    
    // User - Subscription
    case updatePushSubscriptions
    case updateSmsSubscriptions
    case updateKakaoSubscriptions
   
    // AbTest
    case variation
    case variationDetail
    
    // FeatureFlag
    case isFeatureOn
    case featureFlagDetail
    
    // RemoteConfig
    case remoteConfig
    
    // Event
    case track
    
    // InAppMessage
    case getCurrentInAppMessageView
    case closeInAppMessageView
    case handleInAppMessageView
    
    // Screen
    case setCurrentScreen
    
    // Configuration
    case setOptOutTracking
    case isOptOutTracking
    
    // DevTools
    case showUserExplorer
    case hideUserExplorer
}

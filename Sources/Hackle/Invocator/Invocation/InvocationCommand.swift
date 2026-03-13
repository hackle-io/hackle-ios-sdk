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
    
    // Event
    case track
    
    // Screen
    case setCurrentScreen
    
    // Configuration
    case setOptOutTracking
    
    // DevTools
    case showUserExplorer
    case hideUserExplorer
}

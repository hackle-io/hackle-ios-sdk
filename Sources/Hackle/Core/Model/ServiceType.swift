import Foundation

enum ServiceType: String {
    case abTest = "AB_TEST"
    case featureFlag = "FEATURE_FLAG"
    case remoteConfig = "REMOTE_CONFIG"
    case inAppMessage = "IN_APP_MESSAGE"
}

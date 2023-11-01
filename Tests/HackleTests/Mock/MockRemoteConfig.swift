import Foundation
@testable import Hackle

class MockRemoteConfig : HackleRemoteConfig {

    var config: [String: Any] = [:]

    func getString(forKey: String, defaultValue: String) -> String {
        return config[forKey] as? String ?? defaultValue
    }
    
    func getInt(forKey: String, defaultValue: Int) -> Int {
        return config[forKey] as? Int ?? defaultValue
    }
    
    func getDouble(forKey: String, defaultValue: Double) -> Double {
        return config[forKey] as? Double ?? defaultValue
    }
    
    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        return config[forKey] as? Bool ?? defaultValue
    }
    
    
}

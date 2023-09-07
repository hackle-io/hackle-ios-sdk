import Foundation
import SystemConfiguration
import CoreTelephony

class NetworkHelper {
    static func getConnectionType() -> DeviceInfo.ConnectionType {
        guard let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.hackle.io") else {
            return .none
        }

        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        
        let isReachable = flags.contains(.reachable)
        let isWWAN = flags.contains(.isWWAN)
        
        guard isReachable else {
            return .none
        }
        
        guard isWWAN else {
            return .wifi
        }
        
        let networkInfo = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            let carrierType = networkInfo.serviceCurrentRadioAccessTechnology
            guard let _ = carrierType?.first?.value else {
                return .none
            }
            return .mobile
        } else {
            let currentRadio = networkInfo.currentRadioAccessTechnology
            if (currentRadio == nil) {
                return .none
            }
            return .mobile
        }
    }
}

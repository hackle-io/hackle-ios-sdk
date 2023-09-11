import Foundation
import UIKit

class DeviceHelper {
    static func getDeviceModel() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModelIdentifier
        }
        
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let bytes = Data(
            bytes: &systemInfo.machine,
            count: Int(_SYS_NAMELEN)
        )
        guard let deviceModel = String(bytes: bytes, encoding: .ascii) else {
            return UIDevice.current.model
        }
        
        return deviceModel.trimmingCharacters(in: .controlCharacters)
    }
    
    static func getDeviceType() -> String {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "phone"
        case .pad:
            return "tablet"
        case .mac:
            return "pc"
        case .tv:
            return "tv"
        case .carPlay:
            return "car"
        default:
            return "undefined"
        }
    }
}

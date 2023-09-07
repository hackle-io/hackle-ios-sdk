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
    static func getDeviceOrientation() -> DeviceInfo.Orientation {
        var orientation = UIDevice.current.orientation
        let interfaceOrientation: UIInterfaceOrientation?
        
        if #available(iOS 15, *) {
            interfaceOrientation = UIApplication.shared
                .connectedScenes
                .first(where: { $0 is UIWindowScene })
                .flatMap({ $0 as? UIWindowScene })?
                .interfaceOrientation
        } else if #available(iOS 13, *) {
            interfaceOrientation = UIApplication.shared
                .windows
                .first?
                .windowScene?
                .interfaceOrientation
        } else {
            interfaceOrientation = UIApplication.shared
                .statusBarOrientation
        }
        
        if interfaceOrientation != nil {
            if !orientation.isValidInterfaceOrientation {
                switch interfaceOrientation {
                case .portrait:
                    orientation = .portrait
                    break
                case . portraitUpsideDown:
                    orientation = .portraitUpsideDown
                    break;
                case .landscapeLeft:
                    orientation = .landscapeLeft
                    break
                case .landscapeRight:
                    orientation = .landscapeRight
                    break
                default:
                    orientation = .unknown
                    break
                }
            }
        }
        
        if orientation.isLandscape {
            return .landscape
        } else {
            return .portrait
        }
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

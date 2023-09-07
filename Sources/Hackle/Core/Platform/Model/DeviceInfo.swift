import Foundation

struct DeviceInfo {
    let osName: String
    let osVersion: String
    let model: String
    let type: String
    let brand: String
    let manufacturer: String
    let locale: Locale
    let timezone: TimeZone
    let screenInfo: ScreenInfo
    let connectionType: ConnectionType
    
    enum Orientation : String {
        case portrait = "portrait"
        case landscape = "landscape"
    }
    
    struct ScreenInfo {
        let orientation: Orientation
        let width: Int
        let height: Int
    }
    
    enum ConnectionType {
        case none
        case wifi
        case mobile
    }
}

import Foundation

protocol BundleInfo {
    var versionInfo: BundleVersionInfo { get }
    var properties: [String: Any] { get }
}

class BundleInfoImpl: BundleInfo {
    let bundleId: String
    
    let versionInfo: BundleVersionInfo
    var properties: [String : Any] {
        get {
            [
                "packageName": bundleId,
                "versionName": versionInfo.version,
                "versionCode": versionInfo.build
            ]
        }
    }
    
    init() {
        bundleId = Bundle.main.bundleIdentifier ?? ""
        versionInfo = BundleVersionInfo(
            version: Bundle.main.hackleInfoString(forKey: "CFBundleShortVersionString") ?? "",
            build: (Bundle.main.hackleInfoString(forKey: "CFBundleVersion") ?? "").toInt()
        )
    }
}

fileprivate extension String {
    func toInt() -> Int {
        Int(self) ?? 0
    }
}


import Foundation

protocol BundleInfo {
    var currentBundleVersionInfo: BundleVersionInfo { get }
    var previousBundleVersionInfo: BundleVersionInfo? { get }
    var properties: [String: Any] { get }
}

class BundleInfoImpl: BundleInfo {
    let bundleId: String
    
    let currentBundleVersionInfo: BundleVersionInfo
    let previousBundleVersionInfo: BundleVersionInfo?
    var properties: [String : Any] {
        get {
            [
                "packageName": bundleId,
                "versionName": currentBundleVersionInfo.version,
                "versionCode": currentBundleVersionInfo.build
            ]
        }
    }
    
    init() {
        bundleId = Bundle.main.bundleIdentifier ?? ""
        currentBundleVersionInfo = BundleVersionInfo(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            build: (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "").toInt()
        )
        previousBundleVersionInfo = nil // TODO: load in keyvalue
    }
}

extension BundleInfoImpl {
    static func create(keyValueRepository: KeyValueRepository) -> BundleInfo {
        return BundleInfoImpl()
    }
}

fileprivate extension String {
    func toInt() -> Int {
        Int(self) ?? 0
    }
}


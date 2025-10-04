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
    
    init(previousVersion: String?, previousBuild: Int?) {
        bundleId = Bundle.main.bundleIdentifier ?? ""
        currentBundleVersionInfo = BundleVersionInfo(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            build: (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "").toInt()
        )
        
        guard let previousVersion = previousVersion,
              let previousBuild = previousBuild else {
            previousBundleVersionInfo = nil
            return
        }
        
        previousBundleVersionInfo = BundleVersionInfo(
            version: previousVersion,
            build: previousBuild
        )
        
    }
}

extension BundleInfoImpl {
    static func create(keyValueRepository: KeyValueRepository) -> BundleInfo {
        let previousVersion = keyValueRepository.getString(key: "hackle_previous_version")
        let previousBuild = keyValueRepository.getInteger(key: "hackle_previous_build")
        return BundleInfoImpl(previousVersion: previousVersion, previousBuild: previousBuild)
    }
}

fileprivate extension String {
    func toInt() -> Int {
        Int(self) ?? 0
    }
}


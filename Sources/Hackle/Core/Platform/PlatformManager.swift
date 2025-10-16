//
//  PlatformManager.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/14/25.
//

import Foundation

class PlatformManager {
    private var _previousVersion: BundleVersionInfo?
    private var _isDeviceIdCreated: Bool
    
    let device: Device
    let bundleInfo: BundleInfo
    
    var isDeviceIdCreated: Bool {
        get {
            _isDeviceIdCreated
        }
    }
    
    var currentVersion: BundleVersionInfo {
        get {
            bundleInfo.versionInfo
        }
    }
    
    var previousVersion: BundleVersionInfo? {
        get {
            _previousVersion
        }
    }

    init(keyValueRepository: KeyValueRepository) {
        var isIdCreated = false
        let deviceId = PlatformManager.getDeviceId(keyValueRepository: keyValueRepository) { _ in
            isIdCreated = true
            return UUID().uuidString
        }
        device = DeviceImpl(deviceId: deviceId)
        _isDeviceIdCreated = isIdCreated
        _previousVersion = PlatformManager.loadPreviouseBundleVersion(keyValueRepository: keyValueRepository)
        bundleInfo = BundleInfoImpl()
        
        PlatformManager.saveCurrentBundleVersion(keyValueRepository: keyValueRepository, versionInfo: currentVersion)
    }
}

extension PlatformManager {
    fileprivate static let KEY_DEVICE_ID: String = "hackle_device_id"
    fileprivate static let KEY_PREVIOUS_VERSION: String = "hackle_previous_version"
    fileprivate static let KEY_PREVIOUS_BUILD: String  = "hackle_previous_build"
    
    fileprivate static func getDeviceId(keyValueRepository: KeyValueRepository, mapping: (String) -> String) -> String {
        return keyValueRepository.getString(key: KEY_DEVICE_ID, mapping: mapping)
    }
    
    fileprivate static func loadPreviouseBundleVersion(keyValueRepository: KeyValueRepository) -> BundleVersionInfo? {
        guard let previousVersion = keyValueRepository.getString(key: KEY_PREVIOUS_VERSION) else {
            return nil
        }
        let previousBuild = keyValueRepository.getInteger(key: KEY_PREVIOUS_BUILD)
        
        return BundleVersionInfo(version: previousVersion, build: previousBuild)
    }
    
    fileprivate static func saveCurrentBundleVersion(keyValueRepository: KeyValueRepository, versionInfo: BundleVersionInfo) {
        keyValueRepository.putString(key: KEY_PREVIOUS_VERSION, value: versionInfo.version)
        keyValueRepository.putInteger(key: KEY_PREVIOUS_BUILD, value: versionInfo.build)
    }
}

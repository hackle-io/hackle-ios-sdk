//
//  ApplicationInstallDeterminer.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/9/25.
//

import Foundation

class ApplicationInstallDeterminer {
    private let keyValueRepository: KeyValueRepository
    private let device: Device
    private let bundleInfo: BundleInfo
    
    init(keyValueRepository: KeyValueRepository, device: Device, bundleInfo: BundleInfo) {
        self.keyValueRepository = keyValueRepository
        self.device = device
        self.bundleInfo = bundleInfo
    }
    
    func determine() -> ApplicationInstallState {
        let previousVersion = bundleInfo.previousBundleVersionInfo
        let currentVersion = bundleInfo.currentBundleVersionInfo
        
        var state: ApplicationInstallState = if previousVersion == nil && device.isIdCreated {
            .install
        } else if previousVersion != nil && previousVersion != currentVersion {
            .update
        } else {
            .none
        }
        
        saveBundleInfo(currentVersion)
        
        return state
    }
    
    private func saveBundleInfo(_ versionInfo: BundleVersionInfo) {
        keyValueRepository.putString(key: Bundle.KEY_PREVIOUS_VERSION, value: versionInfo.version)
        keyValueRepository.putInteger(key: Bundle.KEY_PREVIOUS_BUILD, value: versionInfo.build)
    }
}

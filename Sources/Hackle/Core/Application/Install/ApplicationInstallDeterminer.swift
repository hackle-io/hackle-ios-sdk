//
//  ApplicationInstallDeterminer.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/9/25.
//

import Foundation

class ApplicationInstallDeterminer {
    private let isDeviceIdCreated: Bool
    
    init(isDeviceIdCreated: Bool) {
        self.isDeviceIdCreated = isDeviceIdCreated
    }
    
    func determine(previousVersion: BundleVersionInfo?, currentVersion: BundleVersionInfo) -> ApplicationInstallState {
        let state: ApplicationInstallState = if previousVersion == nil && isDeviceIdCreated {
            .install
        } else if previousVersion != nil && previousVersion != currentVersion {
            .update
        } else {
            .none
        }
        
        return state
    }
}

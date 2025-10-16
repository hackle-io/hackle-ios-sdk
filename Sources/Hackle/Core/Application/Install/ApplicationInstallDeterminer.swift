//
//  ApplicationInstallDeterminer.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/9/25.
//

import Foundation

class ApplicationInstallDeterminer {
    func determine(previousVersion: BundleVersionInfo?, currentVersion: BundleVersionInfo, isDeviceIdCreated: Bool) -> ApplicationInstallState {
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

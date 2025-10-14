//
//  ApplicationInstallStateListener.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/8/25.
//

import Foundation

protocol ApplicationInstallStateListener {
    func onInstall(version: BundleVersionInfo, timestamp: Date)
    func onUpdate(previousVersion: BundleVersionInfo?, currentVersion: BundleVersionInfo, timestamp: Date)
}

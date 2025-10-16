//
//  ApplicationInstallStateManager.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/8/25.
//

import Foundation

class ApplicationInstallStateManager {
    
    private let platformManager: PlatformManager
    private let applicationInstallDeterminer: ApplicationInstallDeterminer
    private let clock: Clock
    
    private var listeners: [ApplicationInstallStateListener] = []
    private var resolveTimestamp: Date? = nil

    init(
        platformManager: PlatformManager,
        applicationInstallDeterminer: ApplicationInstallDeterminer,
        clock: Clock
    ) {
        self.platformManager = platformManager
        self.applicationInstallDeterminer = applicationInstallDeterminer
        self.clock = clock
    }
    
    func initialize() {
        resolveTimestamp = clock.now()
    }
    
    func addListener(listener: ApplicationInstallStateListener) {
        listeners.append(listener)
    }
    
    func checkApplicationInstall() {
        let state = applicationInstallDeterminer.determine(
            previousVersion: platformManager.previousVersion,
            currentVersion: platformManager.currentVersion,
            isDeviceIdCreated: platformManager.isDeviceIdCreated
        )
        if state != .none {
            Log.debug("ApplicationInstallStateManager.checkApplicationInstall(\(state))")
            // NOTE: ios는 foreground 이벤트 호출 시점이 sdk 초기화 시점보다 빨라
            //  initialize 시점 timestamp 사용
            let timestamp = self.resolveTimestamp ?? self.clock.now()
            if state == .install {
                self.publishInstall(version: platformManager.currentVersion, timestamp: timestamp)
            } else if state == .update {
                self.publishUpdate(previousVersion: platformManager.previousVersion, currentVersion: platformManager.currentVersion, timestamp: timestamp)
            }
        }
    }
    
    private func publishInstall(version: BundleVersionInfo, timestamp: Date) {
        for listener in listeners {
            listener.onInstall(version: version, timestamp: timestamp)
        }
    }
    
    private func publishUpdate(previousVersion: BundleVersionInfo?, currentVersion: BundleVersionInfo, timestamp: Date) {
        for listener in listeners {
            listener.onUpdate(previousVersion: previousVersion, currentVersion: currentVersion, timestamp: timestamp)
        }
    }
}

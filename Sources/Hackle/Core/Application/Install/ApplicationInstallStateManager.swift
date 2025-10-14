//
//  ApplicationInstallStateManager.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/8/25.
//

import Foundation

class ApplicationInstallStateManager {
    
    private let keyValueRepository: KeyValueRepository
    private let applicationInstallDeterminer: ApplicationInstallDeterminer
    private let bundleInfo: BundleInfo
    private let clock: Clock
    
    private var listeners: [ApplicationInstallStateListener] = []
    private var previousVersion: BundleVersionInfo? = nil
    private var resolveTimestamp: Date? = nil
    
    private static var KEY_PREVIOUS_VERSION: String = "hackle_previous_version"
    private static var KEY_PREVIOUS_BUILD: String  = "hackle_previous_build"
    
    init(
        keyValueRepository: KeyValueRepository,
        applicationInstallDeterminer: ApplicationInstallDeterminer,
        bundleInfo: BundleInfo,
        clock: Clock
    ) {
        self.keyValueRepository = keyValueRepository
        self.applicationInstallDeterminer = applicationInstallDeterminer
        self.bundleInfo = bundleInfo
        self.clock = clock
    }
    
    func initialize() {
        previousVersion = loadPreviouseBundleVersion()
        resolveTimestamp = clock.now()
    }
    
    func addListener(listener: ApplicationInstallStateListener) {
        listeners.append(listener)
    }
    
    func checkApplicationInstall() {
        let state = applicationInstallDeterminer.determine(previousVersion: previousVersion, currentVersion: bundleInfo.versionInfo)
        saveCurrentBundleVersion(bundleInfo.versionInfo)
        if state != .none {
            Log.debug("ApplicationInstallStateManager.checkApplicationInstall(\(state))")
            // NOTE: ios는 foreground 이벤트 호출 시점이 sdk 초기화 시점보다 빨라
            //  initialize 시점 timestamp 사용
            let timestamp = self.resolveTimestamp ?? self.clock.now()
            if state == .install {
                self.publishInstall(version: bundleInfo.versionInfo, timestamp: timestamp)
            } else if state == .update {
                self.publishUpdate(previousVersion: previousVersion, currentVersion: bundleInfo.versionInfo, timestamp: timestamp)
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
    
    private func loadPreviouseBundleVersion() -> BundleVersionInfo? {
        guard let previousVersion = keyValueRepository.getString(key: ApplicationInstallStateManager.KEY_PREVIOUS_VERSION) else {
            return nil
        }
        let previousBuild = keyValueRepository.getInteger(key: ApplicationInstallStateManager.KEY_PREVIOUS_BUILD)
        
        return BundleVersionInfo(version: previousVersion, build: previousBuild)
    }
    
    private func saveCurrentBundleVersion(_ versionInfo: BundleVersionInfo) {
        keyValueRepository.putString(key: ApplicationInstallStateManager.KEY_PREVIOUS_VERSION, value: versionInfo.version)
        keyValueRepository.putInteger(key: ApplicationInstallStateManager.KEY_PREVIOUS_BUILD, value: versionInfo.build)
    }
}

//
//  ApplicationEventTracker.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/10/25.
//

import Foundation

class ApplicationEventTracker: ApplicationLifecycleListener, ApplicationInstallStateListener {

    private let userManager: UserManager
    private let core: HackleCore
    private let bundleInfo: BundleInfo
    
    private static let APP_INSTALL_EVENT_KEY = "$app_install"
    private static let APP_UPDATE_EVENT_KEY = "$app_update"
    private static let APP_OPEN_EVENT_KEY = "$app_open"
    private static let APP_BACKGROUND_EVENT_KEY = "$app_background"
    
    init(userManager: UserManager, core: HackleCore, bundleInfo: BundleInfo) {
        self.userManager = userManager
        self.core = core
        self.bundleInfo = bundleInfo
    }
    
    func onInstall(timestamp: Date) {
        let trackEvent = Event.builder(ApplicationEventTracker.APP_INSTALL_EVENT_KEY)
            .property("versionName", bundleInfo.currentBundleVersionInfo.version)
            .property("versionCode", bundleInfo.currentBundleVersionInfo.build)
            .build()
        track(trackEvent, timestamp)
    }
    
    func onUpdate(timestamp: Date) {
        let trackEvent = Event.builder(ApplicationEventTracker.APP_UPDATE_EVENT_KEY)
            .property("versionName", bundleInfo.currentBundleVersionInfo.version)
            .property("versionCode", bundleInfo.currentBundleVersionInfo.build)
            .property("previousVersionName", bundleInfo.previousBundleVersionInfo?.version)
            .property("previousVersionCode", bundleInfo.previousBundleVersionInfo?.build)
            .build()
        track(trackEvent, timestamp)
    }
    
    func onForeground(timestamp: Date, isFromBackground: Bool) {
        let trackEvent = Event.builder(ApplicationEventTracker.APP_OPEN_EVENT_KEY)
            .property("isFromBackground", isFromBackground)
            .build()
        track(trackEvent, timestamp)
    }
    
    func onBackground(timestamp: Date) {
        let trackEvent = Event.builder(ApplicationEventTracker.APP_BACKGROUND_EVENT_KEY)
            .build()
        track(trackEvent, timestamp)
    }
    
    private func track(_ event: Event, _ timestamp: Date) {
        let hackleUser = userManager.resolve(user: nil, hackleAppContext: HackleAppContext.default)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
    }
}

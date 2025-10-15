//
//  ApplicationEventTracker.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/10/25.
//

import Foundation
import UIKit

class ApplicationEventTracker: ApplicationLifecycleListener, ApplicationInstallStateListener {

    private let userManager: UserManager
    private let core: HackleCore
    
    private static let APP_INSTALL_EVENT_KEY = "$app_install"
    private static let APP_UPDATE_EVENT_KEY = "$app_update"
    private static let APP_OPEN_EVENT_KEY = "$app_open"
    private static let APP_BACKGROUND_EVENT_KEY = "$app_background"
    
    init(userManager: UserManager, core: HackleCore) {
        self.userManager = userManager
        self.core = core
    }
    
    func onInstall(version: BundleVersionInfo, timestamp: Date) {
        let trackEvent = Event.builder(ApplicationEventTracker.APP_INSTALL_EVENT_KEY)
            .property("version_name", version.version)
            .property("version_code", version.build)
            .build()
        track(trackEvent, timestamp)
    }
    
    func onUpdate(previousVersion: BundleVersionInfo?, currentVersion: BundleVersionInfo, timestamp: Date) {
        let trackEvent = Event.builder(ApplicationEventTracker.APP_UPDATE_EVENT_KEY)
            .property("version_name", currentVersion.version)
            .property("version_code", currentVersion.build)
            .property("previous_version_name", previousVersion?.version)
            .property("previous_version_code", previousVersion?.build)
            .build()
        track(trackEvent, timestamp)
    }
    
    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        let trackEvent = Event.builder(ApplicationEventTracker.APP_OPEN_EVENT_KEY)
            .property("is_from_background", isFromBackground)
            .build()
        track(trackEvent, timestamp)
    }
    
    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        let trackEvent = Event.builder(ApplicationEventTracker.APP_BACKGROUND_EVENT_KEY)
            .build()
        track(trackEvent, timestamp)
    }
    
    private func track(_ event: Event, _ timestamp: Date) {
        let hackleUser = userManager.resolve(user: nil, hackleAppContext: HackleAppContext.default)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
    }
}

//
//  UserActivityHandler.swift
//  Hackle
//

import Foundation
import UIKit

/// Decides which http(s) links are forwarded to the app as universal links.
/// `applinksOnly` requires a domain match against the entitlements; `forwardAll` skips the check.
enum UniversalLinkPolicy: Sendable {
    case applinksOnly
    case forwardAll
}

/// Relays an `NSUserActivity` to the host app's scene delegate or app delegate.
@MainActor
protocol UserActivityHandler: AnyObject {
    var isContinueInApplicationSupported: Bool { get }
    func continueInScene(_ userActivity: NSUserActivity) -> Bool
    func continueInApplication(_ userActivity: NSUserActivity) -> Bool?
}

final class ApplicationUserActivityHandler: UserActivityHandler {
    nonisolated init() {}

    var isContinueInApplicationSupported: Bool {
        guard let appDelegate = UIUtils.application?.delegate else {
            return false
        }
        return appDelegate.responds(to: #selector(UIApplicationDelegate.application(_:continue:restorationHandler:)))
    }

    func continueInScene(_ userActivity: NSUserActivity) -> Bool {
        guard let scene = UIUtils.activeWindowScene,
              let delegate = scene.delegate,
              delegate.responds(to: #selector(UISceneDelegate.scene(_:continue:)))
        else {
            return false
        }
        delegate.scene?(scene, continue: userActivity)
        return true
    }

    func continueInApplication(_ userActivity: NSUserActivity) -> Bool? {
        guard let application = UIUtils.application, isContinueInApplicationSupported else {
            return nil
        }
        return application.delegate?.application?(
            application,
            continue: userActivity,
            restorationHandler: { _ in }
        )
    }
}

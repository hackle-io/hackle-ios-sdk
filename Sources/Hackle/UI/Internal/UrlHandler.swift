//
//  UrlHandler.swift
//  Hackle
//
//  Created by yong on 2023/07/18.
//

import Foundation
import UIKit

protocol UrlHandler: Sendable {
    @MainActor func open(url: URL)
}

enum UrlSchemes {
    static func isHttp(_ scheme: String) -> Bool {
        return scheme == "http" || scheme == "https"
    }
}

final class PendingUrlHandler: UrlHandler, @unchecked Sendable {
    @MainActor private(set) var pendingUrl: URL?

    @MainActor func open(url: URL) {
        guard let scheme = url.scheme else {
            return
        }
        guard UrlSchemes.isHttp(scheme) else {
            UIUtils.application?.open(url, options: [:]) { success in
                Log.debug("Redirected to: \(url.absoluteString) [success=\(success)]")
            }
            return
        }
        pendingUrl = url
    }

    @MainActor func drain() -> URL? {
        defer { pendingUrl = nil }
        return pendingUrl
    }
}

enum UniversalLinkPolicy: Sendable {
    case applinksOnly
    case forwardAll
}

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

final class ApplicationUrlHandler: NSObject, UrlHandler, @unchecked Sendable {
    private enum Route {
        case openLink
        case continueUserActivity(includingScene: Bool)
    }

    private let policy: UniversalLinkPolicy
    private let entitlements: @Sendable () -> Entitlements
    private let userActivityHandler: any UserActivityHandler
    @MainActor private var pending: (url: URL, includingScene: Bool)?

    init(
        policy: UniversalLinkPolicy = .applinksOnly,
        entitlements: @escaping @Sendable () -> Entitlements = { Entitlements.main },
        userActivityHandler: UserActivityHandler? = nil
    ) {
        self.policy = policy
        self.entitlements = entitlements
        self.userActivityHandler = userActivityHandler ?? ApplicationUserActivityHandler()
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @MainActor var hasPendingUrl: Bool {
        pending != nil
    }

    @MainActor func open(url: URL) {
        guard let scheme = url.scheme else {
            return
        }

        guard UrlSchemes.isHttp(scheme) else {
            openLink(url)
            return
        }

        switch route(url) {
        case .openLink:
            openLink(url)
        case .continueUserActivity(let includingScene):
            openUniversalLink(url, includingScene: includingScene)
        }
    }

    @MainActor private func route(_ url: URL) -> Route {
        switch policy {
        case .forwardAll:
            return .continueUserActivity(includingScene: true)
        case .applinksOnly:
            switch entitlements().isApplink(url) {
            case .some(true):
                return .continueUserActivity(includingScene: true)
            case .some(false):
                return .openLink
            case .none:
                return userActivityHandler.isContinueInApplicationSupported
                    ? .continueUserActivity(includingScene: false)
                    : .openLink
            }
        }
    }

    @MainActor private func openUniversalLink(_ url: URL, includingScene: Bool) {
        // NOTE: RN/Flutter에서 application State가 inactive일 때 userActivity를 처리하면 RN으로 링크가 전달되지 않음
        //  NotificationCenter에서 UIApplication.didBecomeActiveNotification을 구독하고 active 된 후에 처리
        switch UIUtils.application?.applicationState {
        case .active, .background:
            continueUserActivity(url: url, includingScene: includingScene)
        default:
            scheduleOpenWhenActive(url: url, includingScene: includingScene)
        }
    }

    @MainActor private func scheduleOpenWhenActive(url: URL, includingScene: Bool) {
        // 기존 observer 제거 (중복 방지)
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        pending = (url, includingScene)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openPendingUniversalLink),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func openPendingUniversalLink() {
        MainActor.assumeIsolated { [weak self] in
            self?.handlePendingUniversalLink()
        }
    }

    @MainActor private func handlePendingUniversalLink() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        guard let pending else { return }
        self.pending = nil

        continueUserActivity(url: pending.url, includingScene: pending.includingScene)
    }

    @MainActor private func continueUserActivity(url: URL, includingScene: Bool) {
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = url

        if includingScene, userActivityHandler.continueInScene(userActivity) {
            Log.debug("Redirected to universal link via scene: \(url.absoluteString)")
            return
        }

        let success = userActivityHandler.continueInApplication(userActivity)
        Log.debug("Redirected to universal link: \(url.absoluteString) [success=\(success ?? false)]")

        if success != true {
            Log.info("Attempt to open URL alternative")
            openLink(url)
        }
    }

    @MainActor private func openLink(_ url: URL) {
        UIUtils.application?.open(url, options: [:]) { success in
            Log.debug("Redirected to: \(url.absoluteString) [success=\(success)]")
        }
    }
}

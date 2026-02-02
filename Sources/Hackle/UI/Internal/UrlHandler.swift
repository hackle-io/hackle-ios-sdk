//
//  UrlHandler.swift
//  Hackle
//
//  Created by yong on 2023/07/18.
//

import Foundation
import UIKit

protocol UrlHandler {
    @MainActor func open(url: URL)
}

final class ApplicationUrlHandler: NSObject, UrlHandler {
    static let shared: UrlHandler = ApplicationUrlHandler()

    @MainActor private var pendingUrl: URL?

    @MainActor func open(url: URL) {
        guard let scheme = url.scheme else {
            return
        }

        if isHttpScheme(scheme) && isContinueUserActivitySupported() {
            openUniversalLink(url)
        } else {
            openLink(url)
        }
    }

    private func isHttpScheme(_ scheme: String) -> Bool {
        return scheme == "http" || scheme == "https"
    }

    private func isContinueUserActivitySupported() -> Bool {
        guard let appDelegate = UIUtils.application?.delegate else {
            return false
        }
        let selector = #selector(UIApplicationDelegate.application(_:continue:restorationHandler:))
        return appDelegate.responds(to: selector)
    }

    @MainActor private func openUniversalLink(_ url: URL) {
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = url

        // NOTE: RN/Flutter에서 application State가 inactive일 때 userActivity를 처리하면 RN으로 링크가 전달되지 않음
        //  NotificationCenter에서 UIApplication.didBecomeActiveNotification을 구독하고 active 된 후에 처리
        switch UIUtils.application?.applicationState {
        case .active, .background:
            continueUserActivity(userActivity: userActivity)
        default:
            scheduleOpenWhenActive(userActivity: userActivity)
        }
    }

    @MainActor private func scheduleOpenWhenActive(userActivity: NSUserActivity) {
        // 기존 observer 제거 (중복 방지)
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        pendingUrl = userActivity.webpageURL
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openPendingUniversalLink),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @MainActor @objc private func openPendingUniversalLink() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        guard let url = pendingUrl else { return }
        pendingUrl = nil

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = url
        continueUserActivity(userActivity: userActivity)
    }

    @MainActor private func continueUserActivity(userActivity: NSUserActivity) {
        guard let application = UIUtils.application else {
            Log.info("UIApplication is not available")
            return
        }

        let success = application.delegate?.application?(
            application,
            continue: userActivity,
            restorationHandler: { _ in }
        )
        Log.debug("Redirected to universal link: \(userActivity.webpageURL?.absoluteString ?? "") [success=\(success ?? false)]")

        if success != true {
            Log.info("Attempt to open URL alternative")
            if let url = userActivity.webpageURL {
                self.openLink(url)
            }
        }
    }

    private func openLink(_ url: URL) {
        UIUtils.application?.open(url, options: [:]) { success in
            Log.debug("Redirected to: \(url.absoluteString) [success=\(success)]")
        }
    }
}

//
//  UrlHandler.swift
//  Hackle
//
//  Created by yong on 2023/07/18.
//

import Foundation
import UIKit


protocol UrlHandler {
    func open(url: URL)
}

class ApplicationUrlHandler: UrlHandler {
    static let shared: UrlHandler = ApplicationUrlHandler()
    
    func open(url: URL) {
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

    private func openUniversalLink(_ url: URL) {
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

    private func scheduleOpenWhenActive(userActivity: NSUserActivity) {
        var observer: NSObjectProtocol?
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak observer] _ in
            self.continueUserActivity(userActivity: userActivity)
            if let obs = observer {
                NotificationCenter.default.removeObserver(obs)
            }
        }
    }

    private func continueUserActivity(userActivity: NSUserActivity) {
        let success = UIUtils.application?.delegate?.application?(
            UIUtils.application!,
            continue: userActivity,
            restorationHandler: { _ in }
        )
        Log.debug("Redirected to universal link: \(userActivity.webpageURL?.absoluteString ?? "") [success=\(success ?? false)]")

        if success != true {
            Log.info("Attempt to open URL alternative")
            if let url = userActivity.webpageURL {
                openLink(url)
            }
        }
    }

    private func openLink(_ url: URL) {
        UIUtils.application?.open(url, options: [:]) { success in
            Log.debug("Redirected to: \(url.absoluteString) [success=\(success)]")
        }
    }
}

//
// Created by yong on 2020/12/11.
//

import Foundation
import UIKit

protocol AppNotificationObserver {
    func addListener(listener: AppNotificationListener)
}

class DefaultAppNotificationObserver: AppNotificationObserver {

    static let instance = DefaultAppNotificationObserver()

    private var listeners = [AppNotificationListener]()

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(becomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    func addListener(listener: AppNotificationListener) {
        listeners.append(listener)
    }

    @objc private func enterBackground() {
        broadcast(notification: .didEnterBackground)
    }

    @objc private func becomeActive() {
        broadcast(notification: .didBecomeActive)
    }

    private func broadcast(notification: AppNotification) {
        for listener in listeners {
            listener.onNotified(notification: notification)
        }
    }
}

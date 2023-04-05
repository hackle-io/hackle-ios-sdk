//
// Created by yong on 2020/12/11.
//

import Foundation
import UIKit

protocol AppNotificationObserver {
    func addListener(listener: AppNotificationListener)
}

class DefaultAppNotificationObserver: AppNotificationObserver {

    private var listeners = [AppNotificationListener]()
    private let eventQueue: DispatchQueue

    init(eventQueue: DispatchQueue) {
        self.eventQueue = eventQueue
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
        broadcast(notification: .didEnterBackground, timestamp: Date())
    }

    @objc private func becomeActive() {
        broadcast(notification: .didBecomeActive, timestamp: Date())
    }

    private func broadcast(notification: AppNotification, timestamp: Date) {
        eventQueue.async {
            for listener in self.listeners {
                listener.onNotified(notification: notification, timestamp: timestamp)
            }
        }
    }
}

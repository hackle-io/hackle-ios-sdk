//
// Created by yong on 2020/12/11.
//

import Foundation
import UIKit

protocol AppNotificationObserver {
    func addListener(listener: AppStateChangeListener)
}

class DefaultAppNotificationObserver: AppNotificationObserver {

    private var listeners = [AppStateChangeListener]()
    private let eventQueue: DispatchQueue
    private let appStateManager: AppStateManager

    init(eventQueue: DispatchQueue, appStateManager: AppStateManager) {
        self.eventQueue = eventQueue
        self.appStateManager = appStateManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    func addListener(listener: AppStateChangeListener) {
        listeners.append(listener)
    }

    @objc private func enterBackground() {
        broadcast(state: .background, timestamp: Date())
    }

    @objc private func enterForeground() {
        broadcast(state: .foreground, timestamp: Date())
    }

    private func broadcast(state: AppState, timestamp: Date) {
        eventQueue.async {
            for listener in self.listeners {
                listener.onChanged(state: state, timestamp: timestamp)
            }
            self.appStateManager.onChanged(state: state, timestamp: timestamp)
        }
    }
}

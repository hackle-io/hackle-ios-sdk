import Foundation
import UIKit

class EngagementManager: ScreenListener, LifecycleListener {

    private let _lastEngagementTime: AtomicReference<Date?> = AtomicReference(value: nil)
    var lastEngagementTime: Date? {
        _lastEngagementTime.get()
    }

    private var listeners = [EngagementListener]()

    private let userManager: UserManager
    private let screenManager: ScreenManager
    private let minimumEngagementDuration: TimeInterval

    init(userManager: UserManager, screenManager: ScreenManager, minimumEngagementDuration: TimeInterval) {
        self.userManager = userManager
        self.screenManager = screenManager
        self.minimumEngagementDuration = minimumEngagementDuration
    }

    func addListener(listener: EngagementListener) {
        listeners.append(listener)
    }

    private func startEngagement(timestamp: Date) {
        Log.debug("startEngagement(timestamp: \(timestamp))")
        _lastEngagementTime.set(newValue: timestamp)
    }

    private func endEngagement(screen: Screen, timestamp: Date) {
        guard let startTime = _lastEngagementTime.getAndSet(newValue: timestamp) else {
            return
        }

        let engagementDuration = timestamp.timeIntervalSince(startTime)
        if engagementDuration < minimumEngagementDuration {
            return
        }

        let engagement = Engagement(screen: screen, duration: engagementDuration)
        publish(engagement: engagement, user: userManager.currentUser, timestamp: timestamp)
    }

    private func publish(engagement: Engagement, user: User, timestamp: Date) {
        Log.debug("onEngagement(engagement: \(engagement))")
        for listener in listeners {
            listener.onEngagement(engagement: engagement, user: user, timestamp: timestamp)
        }
    }

    func onScreenStarted(previousScreen: Screen?, currentScreen: Screen, user: User, timestamp: Date) {
        startEngagement(timestamp: timestamp)
    }

    func onScreenEnded(screen: Screen, user: User, timestamp: Date) {
        endEngagement(screen: screen, timestamp: timestamp)
    }

    func onLifecycle(lifecycle: Lifecycle, timestamp: Date) {
        switch lifecycle {
        case .viewDidAppear, .didBecomeActive:
            startEngagement(timestamp: timestamp)
            return
        case .viewDidDisappear, .didEnterBackground:
            guard let screen = screenManager.currentScreen else {
                return
            }
            endEngagement(screen: screen, timestamp: timestamp)
            return
        case .viewWillAppear, .viewWillDisappear:
            return
        }
    }
}

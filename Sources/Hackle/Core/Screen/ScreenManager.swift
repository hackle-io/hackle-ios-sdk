import Foundation
import UIKit

protocol ScreenManager {
    var currentScreen: Screen? { get }
}

class DefaultScreenManager: ScreenManager, LifecycleListener {

    private let userManager: UserManager
    private var listeners = [ScreenListener]()

    private let _currentScreen: AtomicReference<Screen?> = AtomicReference(value: nil)
    var currentScreen: Screen? {
        _currentScreen.get()
    }

    init(userManager: UserManager) {
        self.userManager = userManager
    }

    func addListener(listener: ScreenListener) {
        listeners.append(listener)
    }

    func updateScreen(screen: Screen, timestamp: Date) {
        let previousScreen = _currentScreen.getAndSet(newValue: screen)
        if screen == previousScreen {
            return
        }
        let user = userManager.currentUser
        if let previousScreen {
            publishEnd(screen: previousScreen, user: user, timestamp: timestamp)
        }
        publishStart(previousScreen: previousScreen, screen: screen, user: user, timestamp: timestamp)
    }

    private func publishStart(previousScreen: Screen?, screen: Screen, user: User, timestamp: Date) {
        Log.debug("onScreenStarted(previousScreen: \(previousScreen?.description ?? "nil"), currentScreen: \(screen))")
        for listener in listeners {
            listener.onScreenStarted(previousScreen: previousScreen, currentScreen: screen, user: user, timestamp: timestamp)
        }
    }

    private func publishEnd(screen: Screen, user: User, timestamp: Date) {
        Log.debug("onScreenEnded(screen: \(screen))")
        for listener in listeners {
            listener.onScreenEnded(screen: screen, user: user, timestamp: timestamp)
        }
    }

    func onLifecycle(lifecycle: Lifecycle, timestamp: Date) {
        switch lifecycle {
        case .didBecomeActive(let top):
            guard let top = top else {
                return
            }
            updateScreen(screen: Screen.from(top), timestamp: timestamp)
            return
        case .viewDidAppear(_, let top):
            updateScreen(screen: Screen.from(top), timestamp: timestamp)
            return
        case .viewDidDisappear(_, let top):
            updateScreen(screen: Screen.from(top), timestamp: timestamp)
            return
        case .viewWillAppear, .viewWillDisappear, .didEnterBackground:
            return
        }
    }
}

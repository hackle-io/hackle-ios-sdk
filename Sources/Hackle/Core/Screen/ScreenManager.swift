import Foundation
import UIKit

protocol ScreenManager {
    var currentScreen: Screen? { get }
    
    func setCurrentScreen(screen: Screen, timestamp: Date)
}

class DefaultScreenManager: ScreenManager, ViewLifecycleListener {

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
    
    func setCurrentScreen(screen: Screen, timestamp: Date) {
        updateScreen(screen: screen, timestamp: timestamp)
    }

    func updateScreen(screen: Screen, timestamp: Date) {
        Log.debug("ScreenManager.updateScreen(screen: \(screen))")
        let previousScreen = _currentScreen.get()
        if screen == previousScreen {
            return
        }
        let user = userManager.currentUser
        if let previousScreen {
            publishEnd(screen: previousScreen, user: user, timestamp: timestamp)
        }

        _currentScreen.set(newValue: screen)
        publishStart(previousScreen: previousScreen, screen: screen, user: user, timestamp: timestamp)
    }

    private func publishStart(previousScreen: Screen?, screen: Screen, user: User, timestamp: Date) {
        Log.debug("ScreenManager.publishStart(previousScreen: \(previousScreen?.description ?? "nil"), currentScreen: \(screen))")
        for listener in listeners {
            listener.onScreenStarted(previousScreen: previousScreen, currentScreen: screen, user: user, timestamp: timestamp)
        }
    }

    private func publishEnd(screen: Screen, user: User, timestamp: Date) {
        Log.debug("ScreenManager.publishEnd(screen: \(screen))")
        for listener in listeners {
            listener.onScreenEnded(screen: screen, user: user, timestamp: timestamp)
        }
    }

    func onLifecycle(lifecycle: ViewLifecycle, timestamp: Date) {
        Log.debug("ScreenManager.onLifecycle(lifecycle: \(lifecycle))")
        switch lifecycle {
        case .willEnterForeground(let top):
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

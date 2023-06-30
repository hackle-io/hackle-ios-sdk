//
//  AppStateManager.swift
//  Hackle
//
//  Created by yong on 2023/05/10.
//

import Foundation

protocol AppStateManager: AppStateChangeListener {
    var currentState: AppState { get }
    func screen(_ callback: @escaping (_ newScreen: String) -> ()) -> String?
}

class DefaultAppStateManager: AppStateManager {

    private var _currentState: AppState = .background
    var currentState: AppState {
        _currentState
    }

    func onChanged(state: AppState, timestamp: Date) {
        _currentState = state
        Log.debug("AppState changed [\(state)]")
    }

    private var currentScreen: String?

    // Without swizzling, getting top most ViewController from the caller thread is risky.
    // So, returns the previously VC immediately and updates the current VC asynchronously on main thread
    func screen(_ callback: @escaping (String) -> ()) -> String? {
        DispatchQueue.main.async {
            if let vc = UIUtils.topViewController {
                let newScreen = vc.classForCoder.description()
                self.currentScreen = newScreen
                callback(newScreen)
            }
        }
        return currentScreen
    }
}

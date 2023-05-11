//
//  AppStateManager.swift
//  Hackle
//
//  Created by yong on 2023/05/10.
//

import Foundation

protocol AppStateManager: AppStateChangeListener {
    var currentState: AppState { get }
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
}

//
//  AppStateManager.swift
//  Hackle
//
//  Created by yong on 2023/05/10.
//

import Foundation

protocol AppStateManager {
    var currentState: AppState { get }
}

class DefaultAppStateManager: AppStateManager, LifecycleListener {

    private var _currentState: AppState = .background
    var currentState: AppState {
        _currentState
    }

    private var listeners = [AppStateListener]()

    private let queue: DispatchQueue

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func addListener(listener: AppStateListener) {
        listeners.append(listener)
    }

    private func onState(state: AppState, timestamp: Date) {
        queue.async {
            self.publish(state: state, timestamp: timestamp)
        }
    }

    private func publish(state: AppState, timestamp: Date) {
        Log.debug("AppStateManager.publish(state: \(state))")
        for listener in listeners {
            listener.onState(state: state, timestamp: timestamp)
        }
        _currentState = state
    }

    func onLifecycle(lifecycle: Lifecycle, timestamp: Date) {
        Log.debug("AppStateManager.onLifecycle(lifecycle: \(lifecycle))")
        switch lifecycle {
        case .didBecomeActive:
            onState(state: .foreground, timestamp: timestamp)
            return
        case .didEnterBackground:
            onState(state: .background, timestamp: timestamp)
            return
        case .viewWillAppear, .viewDidAppear, .viewWillDisappear, .viewDidDisappear:
            return
        }
    }
}

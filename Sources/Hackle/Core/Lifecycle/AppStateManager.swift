//
//  AppStateManager.swift
//  Hackle
//
//  Created by yong on 2023/05/10.
//

import Foundation

protocol AppStateManager {
    var currentState: ApplicationState { get }
}

class DefaultAppStateManager: AppStateManager, ViewLifecycleListener {

    private var _currentState: ApplicationState = .background
    var currentState: ApplicationState {
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

    private func onState(state: ApplicationState, timestamp: Date) {
        queue.async {
            self.publish(state: state, timestamp: timestamp)
        }
    }

    private func publish(state: ApplicationState, timestamp: Date) {
        Log.debug("AppStateManager.publish(state: \(state))")
        for listener in listeners {
            listener.onState(state: state, timestamp: timestamp)
        }
        _currentState = state
    }

    func onLifecycle(lifecycle: ViewLifecycle, timestamp: Date) {
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

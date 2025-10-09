//
//  ApplicationLifecycleManager.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation

protocol ApplicationLifecycleManager {
    var currentState: ApplicationState { get }

    func addListener(listener: ApplicationLifecycleListener)
}

class DefaultApplicationLifecycleManager: ApplicationLifecycleManager, ApplicationLifecyclePublisher {
    
    static let shared = DefaultApplicationLifecycleManager(
        clock: SystemClock.shared
    )

    private let clock: Clock
    private var queue: DispatchQueue?
    private var listeners: [ApplicationLifecycleListener] = []
    
    private var _currentState: ApplicationState? = nil
    var currentState: ApplicationState {
        get {
            _currentState ?? .background
        }
    }
    
    private init(clock: Clock) {
        self.clock = clock
    }
    
    func setDispatchQueue(queue: DispatchQueue) {
        self.queue = queue
    }
    
    func addListener(listener: ApplicationLifecycleListener) {
        listeners.append(listener)
    }
    
    func didBecomeActive() {
        execute {
            Log.debug("ApplicationLifecycleManager.didBecomeActive")
            for listener in self.listeners {
                listener.onForeground(timestamp: self.clock.now(), isFromBackground: self._currentState == .background)
            }
            self._currentState = .foreground
        }
    }
    
    func didEnterBackground() {
        execute {
            Log.debug("ApplicationLifecycleManager.didEnterBackground")
            for listener in self.listeners {
                listener.onBackground(timestamp: self.clock.now())
            }
            self._currentState = .background
        }
    }
    
    private func execute(_ action: @escaping () -> Void) {
        if let queue = queue {
            queue.async(execute: action)
        } else {
            action()
        }
    }
}

//
//  ApplicationLifecycleManager.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

protocol ApplicationLifecycleManager {
    var currentState: ApplicationState { get }
}

class DefaultApplicationLifecycleManager: ApplicationLifecycleManager, ApplicationLifecyclePublisher {
    
    static let shared = DefaultApplicationLifecycleManager(
        clock: SystemClock.shared
    )

    private let clock: Clock
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
    
    func addListener(listener: ApplicationLifecycleListener) {
        listeners.append(listener)
    }
    
    func didBecomeActive() {
        Log.debug("ApplicationLifecycleManager.didBecomeActive")
        for listener in listeners {
            listener.onForeground(timestamp: clock.now(), isFromBackground: _currentState == .background)
        }
        _currentState = .foreground
    }
    
    func didEnterBackground() {
        Log.debug("ApplicationLifecycleManager.didEnterBackground")
        for listener in listeners {
            listener.onBackground(timestamp: clock.now())
        }
        _currentState = .background
    }
}

//
//  ApplicationLifecycleManager.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation
import UIKit

protocol ApplicationLifecycleManager {
    var currentState: ApplicationState { get }

    func addListener(listener: ApplicationLifecycleListener)
}

class DefaultApplicationLifecycleManager: ApplicationLifecycleManager, ApplicationLifecyclePublisher {
    static let shared = DefaultApplicationLifecycleManager(
        viewManager: DefaultViewManager.shared,
        clock: SystemClock.shared
    )

    private let viewManager: ViewManager
    private let clock: Clock
    private var queue: DispatchQueue?
    private var listeners: [ApplicationLifecycleListener] = []
    
    private var _currentState: ApplicationState? = nil
    var currentState: ApplicationState {
        get {
            _currentState ?? .background
        }
    }
    var firstLaunch: AtomicReference<Bool> = AtomicReference(value: true)
    
    private init(viewManager: ViewManager, clock: Clock) {
        self.viewManager = viewManager
        self.clock = clock
    }
    
    func setDispatchQueue(queue: DispatchQueue) {
        self.queue = queue
    }
    
    func addListener(listener: ApplicationLifecycleListener) {
        listeners.append(listener)
    }
    
    func didBecomeActive() {
        guard firstLaunch.get() else {
            return
        }
        
        self.willEnterForeground()
    }
    
    func publishWillEnterForegroundIfNeeded() {
        // 현재 상태가 명시적으로 active일 때만 publish
        // - didFinishLaunchingWithOptions: inactive
        // - willEnterForeground: active
        // - didBecomeActive: active
        // - didEnterBackground: background
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                guard self.firstLaunch.get() else {
                    return
                }
                self.willEnterForeground()
            }
        }
    }
    
    func willEnterForeground() {
        firstLaunch.set(newValue: false)
        let top = viewManager.topViewController()
        execute {
            Log.debug("ApplicationLifecycleManager.willEnterForeground")
            for listener in self.listeners {
                listener.onForeground(top, timestamp: self.clock.now(), isFromBackground: self._currentState == .background)
            }
            self._currentState = .foreground
        }
    }
    
    func didEnterBackground() {
        let top = viewManager.topViewController()
        execute {
            Log.debug("ApplicationLifecycleManager.didEnterBackground")
            for listener in self.listeners {
                listener.onBackground(top, timestamp: self.clock.now())
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

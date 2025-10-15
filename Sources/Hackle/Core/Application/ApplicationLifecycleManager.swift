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
    var firstLaunch: Bool {
        get {
            _currentState == nil
        }
    }
    
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
        guard firstLaunch else {
            return
        }
        
        // ios 13 미만은 앱 최초 실행 시 willEnterForeground가 호출이 안되어 여기서 호출
        if #unavailable(iOS 13.0) {
            willEnterForeground()
        }
    }
    
    func publishWillEnterForegroundIfNeeded() {
        // 현재 상태가 명시적으로 active일 때만 publish
        // - didFinishLaunchingWithOptions: inactive
        // - didBecomeActive: active
        // - willEnterForeground: active
        // - didEnterBackground: background
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                guard self.firstLaunch else {
                    return
                }
                self.willEnterForeground()
            }
        }
    }
    
    func willEnterForeground() {
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

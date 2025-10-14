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
        clock: SystemClock.shared
    )

    private let clock: Clock
    private var queue: DispatchQueue?
    private var listeners: [ApplicationLifecycleListener] = []
    private var firstLaunch: AtomicReference<Bool> = AtomicReference(value: true)
    
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
    
    func publishWillEnterForegroundIfNeeded() {
        // 현재 상태가 명시적으로 active일 때만 publish
        // - didFinishLaunchingWithOptions: inactive
        // - didBecomeActive: active
        // - willEnterForeground: active
        // - didEnterBackground: background
        DispatchQueue.main.async {
            guard self.firstLaunch.get() else {
                return
            }
            
            if UIApplication.shared.applicationState == .active {
                self.willEnterForeground()
            }
        }
    }
    
    func didBecomeActive() {
        // NOTE: ios 13 미만에서는 앱 최초 실행 시에는 willEnterForeground가 발행이 안되어
        //  didBecomeActive에서 처리
        if #unavailable(iOS 13.0) {
            guard firstLaunch.get() else {
                return
            }
            
            willEnterForeground()
        }
    }
    
    func willEnterForeground() {
        firstLaunch.set(newValue: false)
        execute {
            Log.debug("ApplicationLifecycleManager.willEnterForeground")
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

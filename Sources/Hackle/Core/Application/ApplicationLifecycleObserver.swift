//
//  ApplicationLifecycleObserver.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation
import UIKit

class ApplicationLifecycleObserver {
    
    static let shared = ApplicationLifecycleObserver()

    private let initialized: AtomicReference<Bool> = AtomicReference(value: false)
    private var publishers: [ApplicationLifecyclePublisher] = []
    private var firstLaunch: AtomicReference<Bool> = AtomicReference(value: true)

    private init() {
    }
    
    func initialize() {
        guard initialized.compareAndSet(expect: false, update: true) else {
            Log.debug("ApplicationLifecycleObserver already initialized.")
            return
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        if #unavailable(iOS 13.0) {
            // NOTE: ios 13 미만에서는 앱 최초 실행 시에는 willEnterForeground가 발행이 안되어
            //  didBecomeActive에서 처리
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }
    
    func addPublisher(publisher: ApplicationLifecyclePublisher) {
        publishers.append(publisher)
    }
    
    func publishWillEnterForegroundIfNeeded() {
        guard firstLaunch.get() else {
            return
        }
        
        // 현재 상태가 명시적으로 active일 때만 publish
        // - didFinishLaunchingWithOptions: inactive
        // - didBecomeActive: active
        // - willEnterForeground: active
        // - didEnterBackground: background
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                self.willEnterForeground()
            }
        }
    }
    
    @objc func didBecomeActive() {
        guard firstLaunch.get() else {
            return
        }
        
        willEnterForeground()
    }

    @objc func willEnterForeground() {
        firstLaunch.set(newValue: false)
        for publisher in publishers {
            publisher.willEnterForeground()
        }
    }

    @objc func didEnterBackground() {
        for publisher in publishers {
            publisher.didEnterBackground()
        }
    }
}

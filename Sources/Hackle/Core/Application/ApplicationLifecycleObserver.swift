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
    private var firstLaunch: AtomicReference<Bool> = AtomicReference(value: false)

    private init() {
    }
    
    func initialize() {
        guard initialized.compareAndSet(expect: false, update: true) else {
            Log.debug("ApplicationLifecycleObserver already initialized.")
            return
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    func addPublisher(publisher: ApplicationLifecyclePublisher) {
        publishers.append(publisher)
    }
    
    func publishDidBecomeActiveIfNeeded() {
        // 현재 상태가 명시적으로 active일 때만 publish
        // - didFinishLaunchingWithOptions: inactive
        // - didBecomeActive: active
        // - didEnterBackground: background
        
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active && self.firstLaunch.get() == true {
                self.didBecomeActive()
            }
        }
    }

    @objc func didBecomeActive() {
        firstLaunch.set(newValue: false)
        for publisher in publishers {
            publisher.didBecomeActive()
        }
    }

    @objc func didEnterBackground() {
        for publisher in publishers {
            publisher.didEnterBackground()
        }
    }
}

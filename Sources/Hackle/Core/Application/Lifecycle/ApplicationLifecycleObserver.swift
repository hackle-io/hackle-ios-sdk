//
//  ApplicationLifecycleObserver.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation
import UIKit

class ApplicationLifecycleObserver {
    
    static let shared = ApplicationLifecycleObserver(
        publisher: DefaultApplicationLifecycleManager.shared
    )

    private let initialized: AtomicReference<Bool> = AtomicReference(value: false)
    private let publisher: ApplicationLifecyclePublisher

    private init(publisher: ApplicationLifecyclePublisher) {
        self.publisher = publisher
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
    }
    
    @objc func didBecomeActive() {
        publisher.didBecomeActive()
    }

    @objc func willEnterForeground() {
        publisher.willEnterForeground()
    }

    @objc func didEnterBackground() {
        publisher.didEnterBackground()
    }
}

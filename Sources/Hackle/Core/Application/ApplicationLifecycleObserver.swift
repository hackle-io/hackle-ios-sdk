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

    @objc func didBecomeActive() {
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

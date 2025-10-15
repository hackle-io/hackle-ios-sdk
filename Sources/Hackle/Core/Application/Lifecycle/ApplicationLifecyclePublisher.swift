//
//  ApplicationLifecyclePublisher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation
import UIKit

protocol ApplicationLifecyclePublisher {
    /// 앱 실행 여부
    /// - Returns:
    ///   - true: 앱이 완전히 꺼진 상태에서 실행
    ///   - false: 백그라운드에서 실행
    var firstLaunch: AtomicReference<Bool> { get }

    func didBecomeActive()
    func willEnterForeground()
    func didEnterBackground()
}

extension ApplicationLifecyclePublisher {
    func didBecomeActive() {
        guard firstLaunch.getAndSet(newValue: false) else {
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
                guard self.firstLaunch.getAndSet(newValue: false) else {
                    return
                }
                self.willEnterForeground()
            }
        }
    }
}

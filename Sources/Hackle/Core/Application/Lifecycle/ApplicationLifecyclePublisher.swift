//
//  ApplicationLifecyclePublisher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation
import UIKit

protocol ApplicationLifecyclePublisher {
    @MainActor func didBecomeActive()
    @MainActor func willEnterForeground()
    @MainActor func didEnterBackground()
    @MainActor func publishWillEnterForegroundIfNeeded()
}

//
//  ApplicationLifecyclePublisher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation
import UIKit

protocol ApplicationLifecyclePublisher {
    func didBecomeActive()
    func willEnterForeground()
    func didEnterBackground()
    func publishWillEnterForegroundIfNeeded()
}

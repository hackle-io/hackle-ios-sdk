//
//  ApplicationLifecycleProvider.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation
import UIKit

@objc public final class ApplicationLifecycleProvider: NSObject {
    @objc func load() {
        ApplicationLifecycleObserver.shared.initialize()
    }
}

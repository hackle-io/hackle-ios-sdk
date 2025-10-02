//
//  ApplicationLifecycleProvider.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation
import UIKit

@objc public final class ApplicationLifecycleProvider: NSObject {
    @objc public static func setupInitialObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidFinishLaunching),
            name: UIApplication.didFinishLaunchingNotification,
            object: nil
        )
    }
    
    @objc private static func handleDidFinishLaunching() {
        ApplicationLifecycleObserver.shared.initialize()
    }
}

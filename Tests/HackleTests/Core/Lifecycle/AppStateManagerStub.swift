//
//  AppStateManagerStub.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
@testable import Hackle
import UIKit


class ApplicationLifecycleManagerStub: ApplicationLifecycleManager {

    var currentState: ApplicationState
    var currentScreen: String?
    var callbackScreen: String?

    var delay: Double = 0.0

    init(currentState: ApplicationState = .background, currentScreen: String? = nil, callbackScreen: String? = nil) {
        self.currentState = currentState
        self.currentScreen = currentScreen
        self.callbackScreen = callbackScreen
    }

    private let queue = DispatchQueue(label: "ApplicationLifecycleManagerStub", qos: .utility)

    func sync() {
        queue.sync {
        }
    }

    func screen(_ callback: @escaping (String) -> ()) -> String? {
        queue.asyncAfter(deadline: .now() + delay) {
            if let sc = self.callbackScreen {
                callback(sc)
            }
        }
        return currentScreen
    }

    func addListener(listener: ApplicationLifecycleListener) {
        // Stub implementation
    }

    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        currentState = .foreground
    }

    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        currentState = .background
    }
}

//
//  AppStateManagerStub.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
@testable import Hackle


class AppStateManagerStub: AppStateManager {

    var currentState: AppState
    var currentScreen: String?
    var callbackScreen: String?

    var delay: Double = 0.0

    init(currentState: AppState = .background, currentScreen: String? = nil, callbackScreen: String? = nil) {
        self.currentState = currentState
        self.currentScreen = currentScreen
        self.callbackScreen = callbackScreen
    }

    private let queue = DispatchQueue(label: "AppStateManagerStub", qos: .utility)

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

    func onChanged(state: AppState, timestamp: Date) {
        currentState = state
    }
}
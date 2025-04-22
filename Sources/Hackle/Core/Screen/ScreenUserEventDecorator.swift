//
//  ScreenUserEventDecorator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/22/25.
//

import Foundation

class ScreenUserEventDecorator: UserEventDecorator {
    private let screenManager: ScreenManager
    
    init(screenManager: ScreenManager) {
        self.screenManager = screenManager
    }
    
    func decorate(event: UserEvent) -> UserEvent {
        guard let screen = screenManager.currentScreen else {
            return event
        }
        let newUser = event.user.toBuilder()
            .hackleProperties([
                "screenName": screen.name,
                "screenClass": screen.className
            ])
            .build()

        return event.with(user: newUser)
    }
}

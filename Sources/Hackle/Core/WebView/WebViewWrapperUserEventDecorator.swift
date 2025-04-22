//
//  WebViewWrapperUserEventDecorator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/22/25.
//

import Foundation

class WebViewWrapperUserEventDecorator: UserEventDecorator {
    func decorate(event: UserEvent) -> UserEvent {
        let decoratedUser = event.user.toBuilder()
            .clearProperties()
            .build()
        
        return event.with(user: decoratedUser)
    }
}

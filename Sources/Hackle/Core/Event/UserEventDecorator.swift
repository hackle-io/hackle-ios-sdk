//
//  UserEventDecorator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/22/25.
//

protocol UserEventDecorator {
    func decorate(event: UserEvent) -> UserEvent
}

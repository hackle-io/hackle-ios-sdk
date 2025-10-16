//
//  UserDecorator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/14/25.
//

protocol UserDecorator {
    func decorate(user: HackleUser) -> HackleUser
}

extension HackleUser {
    func decorateWith(docorator: UserDecorator) -> HackleUser {
        docorator.decorate(user: self)
    }
}

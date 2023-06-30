//
//  UserEventListener.swift
//  Hackle
//
//  Created by yong on 2023/06/05.
//

import Foundation

protocol UserEventListener {
    func onEvent(event: UserEvent)
}

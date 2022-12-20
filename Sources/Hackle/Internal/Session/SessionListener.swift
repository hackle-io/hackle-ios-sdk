//
//  SessionListener.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation

protocol SessionListener {

    func onSessionStarted(session: Session, timestamp: Date)

    func onSessionEnded(session: Session, timestamp: Date)
}
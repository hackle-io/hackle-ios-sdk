//
//  Session.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation

struct Session: Equatable {
    let id: String

    static let UNKNOWN = Session(id: "0.ffffffff")

    static func create(timestamp: Date) -> Session {
        let hash = String(UUID().uuidString.lowercased().prefix(8))
        return Session(id: "\(timestamp.epochMillis).\(hash)")
    }
}
//
//  HackleAppContext.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/12/25.
//

struct HackleAppContext {
    let browserProperties: [String: Any]
}

extension HackleAppContext {
    static let `default` = HackleAppContext(browserProperties: [:])
    
    static func create(browserProperties: [String: Any]) -> HackleAppContext {
        HackleAppContext(browserProperties: browserProperties)
    }
}

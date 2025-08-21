//
//  PIIEventTracker.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Foundation

/// Personally Identifiable Information Property
enum PIIProperty: String {
    case phoneNumber = "$phone_number"
}

extension PropertyOperations {
    /// property operations를 secured event로 변환
    /// - Returns: Hackle Event
    func toSecuredEvent() -> Event {
        let builder = Event.builder("$secured_properties")
        for (operation, properties) in asDictionary() {
            builder.property(operation.rawValue, properties)
        }
        return builder.build()
    }
}

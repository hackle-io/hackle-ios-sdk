//
//  PIIEventTracker.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Foundation

/// Personally Identifiable Information Event Manager
protocol PIIEventManager {
    /// 전화번호를 설정
    ///
    /// set 할 때마다 기존 전화번호는 덮어쓰기 됩니다.
    /// - Parameters:
    ///   - phoneNumber: 전화번호
    func setPhoneNumber(phoneNumber: PhoneNumber) -> Event
    /// 전화번호를 삭제
    func unsetPhoneNumber() -> Event
}

class DefaultPIIEventManager: PIIEventManager {
    
    func setPhoneNumber(phoneNumber: PhoneNumber) -> Event {
        let properties = PropertyOperationsBuilder()
            .set(PIIProperty.phoneNumber.rawValue, phoneNumber.value)
            .build()
        return properties.toSecuredEvent()
    }
    
    func unsetPhoneNumber() -> Event {
        let properties = PropertyOperationsBuilder()
            .unset(PIIProperty.phoneNumber.rawValue)
            .build()
        return properties.toSecuredEvent()
    }
}

/// Personally Identifiable Information Property
enum PIIProperty: String {
    case phoneNumber = "$phone_number"
}

extension PropertyOperations {
    /// property operations를 secured event로 변환
    /// - Returns: Hackle Event
    fileprivate func toSecuredEvent() -> Event {
        let builder = Event.builder("$secured_properties")
        for (operation, properties) in asDictionary() {
            builder.property(operation.rawValue, properties)
        }
        return builder.build()
    }
}

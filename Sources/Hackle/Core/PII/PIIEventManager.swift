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
    ///   - user: 유저
    ///   - timestamp: 설정 시간
    func setPhoneNumber(phoneNumber: PhoneNumber, timestamp: Date)
    /// 전화번호를 삭제
    /// - Parameters:
    ///   - user: 유저
    ///   - timestamp: 삭제 시간
    func unsetPhoneNumber(timestamp: Date)
}

class DefaultPIIEventManager: PIIEventManager {
    
    private let userManager: UserManager
    private let core: HackleCore
    
    init(userManager: UserManager, core: HackleCore) {
        self.userManager = userManager
        self.core = core
    }
    
    func setPhoneNumber(phoneNumber: PhoneNumber, timestamp: Date) {
        let properties = PropertyOperationsBuilder()
            .set(PIIProperty.phoneNumber.rawValue, phoneNumber.value)
            .build()
        let event = properties.toSecuredEvent()
        track(event: event, timestamp: timestamp)
    }
    
    func unsetPhoneNumber(timestamp: Date) {
        let properties = PropertyOperationsBuilder()
            .unset(PIIProperty.phoneNumber.rawValue)
            .build()
        let event = properties.toSecuredEvent()
        track(event: event, timestamp: timestamp)
    }
    
    /// secured properties event를 추적
    /// - Parameters:
    ///   - event: 이벤트
    ///   - user: 유저
    ///   - timestamp: 이벤트 발생 시각
    private func track(event: Event, timestamp: Date) {
        let hackleUser = userManager.resolve(user: nil)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
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

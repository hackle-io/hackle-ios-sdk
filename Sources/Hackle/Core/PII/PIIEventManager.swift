//
//  PIIEventTracker.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Foundation

protocol PIIEventManager {
    func setPhoneNumber(phoneNumber: String, hackleUser: HackleUser, timestamp: Date)
    func unsetPhoneNumber(hackleUser: HackleUser, timestamp: Date)
}

class DefaultPIIEventManager: PIIEventManager {
    private let core: HackleCore
    
    init(core: HackleCore) {
        self.core = core
    }
    
    func setPhoneNumber(phoneNumber: String, hackleUser: HackleUser, timestamp: Date) {
        guard let phoneNumber = PhoneNumber.tryParse(phoneNumber: phoneNumber) else {
            return
        }
        
        let properties = PropertyOperationsBuilder()
            .set(PIIProperty.phoneNumber.rawValue, phoneNumber)
            .build()
        let event = properties.toSecuredEvent()
        track(event: event, hackleUser: hackleUser, timestamp: timestamp)
    }
    
    func unsetPhoneNumber(hackleUser: HackleUser, timestamp: Date) {
        let properties = PropertyOperationsBuilder()
            .unset(PIIProperty.phoneNumber.rawValue)
            .build()
        let event = properties.toSecuredEvent()
        track(event: event, hackleUser: hackleUser, timestamp: timestamp)
    }
    
    private func track(event: Event, hackleUser: HackleUser, timestamp: Date) {
        core.track(event: event, user: hackleUser, timestamp: timestamp)
    }

}

enum PIIProperty: String {
    case phoneNumber = "$phone_number"
}

extension PropertyOperations {
    fileprivate func toSecuredEvent() -> Event {
        let builder = Event.builder("$secured_properties")
        for (operation, properties) in asDictionary() {
            builder.property(operation.rawValue, properties)
        }
        return builder.build()
    }
}

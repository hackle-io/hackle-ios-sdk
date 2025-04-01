//
//  PIIEventTracker.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Foundation

protocol PIIEventManager {
    func setPhoneNumber(phoneNumber: String, user: User, timestamp: Date)
    func unsetPhoneNumber(user: User, timestamp: Date)
}

class DefaultPIIEventManager: PIIEventManager {
    
    private let userManager: UserManager
    private let core: HackleCore
    
    init(userManager: UserManager, core: HackleCore) {
        self.userManager = userManager
        self.core = core
    }
    
    func setPhoneNumber(phoneNumber: String, user: User, timestamp: Date) {
        let filteredPhoneNumber = PhoneNumber.filtered(phoneNumber: phoneNumber)
        let properties = PropertyOperationsBuilder()
            .set(PIIProperty.phoneNumber.rawValue, filteredPhoneNumber)
            .build()
        let event = properties.toSecuredEvent()
        track(event: event, user: user, timestamp: timestamp)
    }
    
    func unsetPhoneNumber(user: User, timestamp: Date) {
        let properties = PropertyOperationsBuilder()
            .unset(PIIProperty.phoneNumber.rawValue)
            .build()
        let event = properties.toSecuredEvent()
        track(event: event, user: user, timestamp: timestamp)
    }
    
    private func track(event: Event, user: User, timestamp: Date) {
        let hackleUser = userManager.toHackleUser(user: user)
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

//
//  HackleUserResolver.swift
//  Hackle
//
//  Created by yong on 2022/05/29.
//

import Foundation


protocol HackleUserResolver {
    func resolve(user: User) -> HackleUser
}


class DefaultHackleUserResolver: HackleUserResolver {

    private let device: Device

    init(device: Device) {
        self.device = device
    }

    func resolve(user: User) -> HackleUser {
        HackleUser.builder()
            .identifiers(user.identifiers)
            .identifier(.id, user.id)
            .identifier(.id, device.id, overwrite: false)
            .identifier(.user, user.userId)
            .identifier(.device, user.deviceId)
            .identifier(.device, device.id, overwrite: false)
            .identifier(.hackleDevice, device.id)
            .properties(user.properties)
            .hackleProperties(device.properties)
            .build()
    }
}

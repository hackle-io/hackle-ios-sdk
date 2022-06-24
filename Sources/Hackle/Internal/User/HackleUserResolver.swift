//
//  HackleUserResolver.swift
//  Hackle
//
//  Created by yong on 2022/05/29.
//

import Foundation


protocol HackleUserResolver {
    func resolveOrNil(user: User) -> HackleUser?
}


class DefaultHackleUserResolver: HackleUserResolver {

    private let device: Device

    init(device: Device) {
        self.device = device
    }

    func resolveOrNil(user: User) -> HackleUser? {
        let decoratedUser = decorateUser(user: user)
        let hackleUser = HackleUser.of(user: decoratedUser, hackleProperties: device.properties)

        if hackleUser.identifiers.isEmpty {
            return nil
        }

        return hackleUser
    }

    private func decorateUser(user: User) -> User {
        if user.deviceId != nil {
            return user
        } else {
            return user.withDeviceId(deviceId: device.id)
        }
    }
}

extension User {
    func withDeviceId(deviceId: String) -> User {
        return User(id: id, userId: userId, deviceId: deviceId, identifiers: identifiers, properties: properties)
    }
}

import Foundation

protocol InAppMessageIdentifierChecker {
    func isIdentifierChanged(old: Identifiers, new: Identifiers) -> Bool
}

class DefaultInAppMessageIdentifierChecker: InAppMessageIdentifierChecker {
    func isIdentifierChanged(old: Identifiers, new: Identifiers) -> Bool {

        if let oldUserId = old[IdentifierType.user.rawValue],
           let newUserId = new[IdentifierType.user.rawValue] {
            return oldUserId != newUserId
        }

        if let oldDeviceId = old[IdentifierType.device.rawValue],
           let newDeviceId = new[IdentifierType.device.rawValue] {
            return oldDeviceId != newDeviceId
        }

        return false
    }
}

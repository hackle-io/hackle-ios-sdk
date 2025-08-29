import Foundation

protocol InAppMessageResetProcessor {
    func process(oldUser: User, newUser: User)
}

class DefaultInAppMessageResetProcessor: InAppMessageResetProcessor {

    private let identifierChecker: InAppMessageIdentifierChecker
    private let delayManager: InAppMessageDelayManager

    init(identifierChecker: InAppMessageIdentifierChecker, delayManager: InAppMessageDelayManager) {
        self.identifierChecker = identifierChecker
        self.delayManager = delayManager
    }

    func process(oldUser: User, newUser: User) {
        let isIdentifierChanged = identifierChecker.isIdentifierChanged(old: oldUser.resolvedIdentifiers, new: newUser.resolvedIdentifiers)
        if isIdentifierChanged {
            let delays = delayManager.cancelAll()
            Log.debug("InAppMessage Delay cancelled. count: \(delays.count)")
        }
    }
}

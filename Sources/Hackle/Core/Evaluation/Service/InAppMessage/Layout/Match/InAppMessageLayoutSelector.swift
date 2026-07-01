import Foundation

class InAppMessageLayoutSelector {
    func select(inAppMessage: InAppMessage, condition: (InAppMessage.Message) -> Bool) throws -> InAppMessage.Message {
        guard let message = inAppMessage.messageContext.messages.first(where: condition) else {
            throw HackleError.error("InAppMessage must be decided [\(inAppMessage.key)]")
        }
        return message
    }
}

import Foundation

protocol InAppMessageActionHandler {
    func supports(action: InAppMessage.Action) -> Bool
    @MainActor func handle(view: InAppMessageView, action: InAppMessage.Action)
}

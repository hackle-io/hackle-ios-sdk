import Foundation

protocol InAppMessageViewEventActor {
    func supports(type: InAppMessageViewEventType) -> Bool
    @MainActor func action(view: InAppMessageView, event: InAppMessageViewEvent)
}

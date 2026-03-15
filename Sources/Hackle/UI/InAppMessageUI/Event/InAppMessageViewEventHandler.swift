import Foundation

/// Handles `InAppMessageViewEvent` occurred in `InAppMessageView`
protocol InAppMessageViewEventHandler {
    func supports(handleType: InAppMessageViewEventHandleType) -> Bool
    @MainActor func handle(view: InAppMessageView, event: InAppMessageViewEvent)
}

/// The type of handling to perform when an `InAppMessageViewEvent` occurs.
enum InAppMessageViewEventHandleType: CaseIterable {
    /// Tracks the events by sending it to server.
    case track

    /// Executes the behavioral response to the event (e.g, open link, close view)
    case action
}

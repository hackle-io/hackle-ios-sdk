import Foundation

class InAppMessageViewEventTrackHandler: InAppMessageViewEventHandler {
    private let tracker: InAppMessageEventTracker

    init(tracker: InAppMessageEventTracker) {
        self.tracker = tracker
    }

    func supports(handleType: InAppMessageViewEventHandleType) -> Bool {
        return handleType == .track
    }

    func handle(view: InAppMessageView, event: InAppMessageViewEvent) {
        tracker.track(context: view.context, event: event)
    }
}

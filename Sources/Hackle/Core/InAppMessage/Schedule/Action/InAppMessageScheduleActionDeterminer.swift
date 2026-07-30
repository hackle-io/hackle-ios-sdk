import Foundation


protocol InAppMessageScheduleActionDeterminer {
    func determine(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleAction
}

class DefaultInAppMessageScheduleActionDeterminer: InAppMessageScheduleActionDeterminer {
    func determine(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleAction {
        let delay = request.delay

        let action: InAppMessageScheduleAction
        if delay > 0 {
            action = .delay
        } else if DefaultInAppMessageScheduleActionDeterminer.deliverDurationRange.contains(delay) {
            action = .deliver
        } else if delay < DefaultInAppMessageScheduleActionDeterminer.deliverDurationThreshold {
            action = .ignore
        } else {
            throw HackleError.error("InAppMessageScheduleAction cannot be determined (key: \(request.schedule.inAppMessageKey))")
        }
        Log.debug("InAppMessage ScheduleAction determined. action: \(action), dispatchId: \(request.schedule.dispatchId)")
        return action
    }

    private static let deliverDurationThreshold: TimeInterval = -60
    private static let deliverDurationRange = (deliverDurationThreshold...0)
}

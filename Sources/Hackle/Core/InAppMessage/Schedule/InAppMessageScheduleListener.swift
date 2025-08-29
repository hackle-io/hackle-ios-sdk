import Foundation

protocol InAppMessageScheduleListener {
    func onSchedule(request: InAppMessageScheduleRequest)
}

import Foundation

protocol InAppMessageScheduler {
    func support(scheduleType: InAppMessageScheduleType) -> Bool
    func deliver(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse
    func delay(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse
    func ignore(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse
}

extension InAppMessageScheduler {
    func schedule(action: InAppMessageScheduleAction, request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        switch action {
        case .deliver:
            return try deliver(request: request)
        case .delay:
            return try delay(request: request)
        case .ignore:
            return try ignore(request: request)
        }
    }
}

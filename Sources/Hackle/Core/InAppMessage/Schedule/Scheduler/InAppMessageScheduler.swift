import Foundation

protocol InAppMessageScheduler {
    func support(scheduleType: InAppMessageScheduleType) -> Bool
    func deliver(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse
    func delay(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse
    func ignore(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse
}

extension InAppMessageScheduler {
    func schedule(action: InAppMessageScheduleAction, request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse {
        switch action {
        case .deliver:
            return try await deliver(request: request)
        case .delay:
            return try await delay(request: request)
        case .ignore:
            return try await ignore(request: request)
        }
    }
}

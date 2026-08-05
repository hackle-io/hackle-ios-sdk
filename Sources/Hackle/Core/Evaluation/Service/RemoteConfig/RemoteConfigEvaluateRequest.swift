import Foundation

protocol RemoteConfigEvaluateRequest: EvaluateRequest {
    var parameter: RemoteConfigParameter { get }
    var requiredType: HackleValueType { get }
}

extension RemoteConfigEvaluateRequest {
    var entity: Entity { parameter }
}

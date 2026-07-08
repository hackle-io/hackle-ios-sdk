import Foundation

protocol RemoteConfigEvaluateRequest: EvaluateRequest {
    var parameter: RemoteConfigParameter { get }
    var requiredType: HackleValueType { get }
}

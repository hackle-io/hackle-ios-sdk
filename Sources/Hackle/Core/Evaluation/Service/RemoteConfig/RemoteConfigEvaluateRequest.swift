import Foundation

protocol RemoteConfigEvaluateRequest: EvaluateRequest {
    var parameter: RemoteConfigParameter { get }
    var defaultValue: HackleValue { get }
}

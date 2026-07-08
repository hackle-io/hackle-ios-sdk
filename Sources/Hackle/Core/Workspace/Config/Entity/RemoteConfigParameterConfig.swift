import Foundation

protocol RemoteConfigParameterConfig: RemoteConfigParameter, ConfigEntity {
    var identifierType: String { get }
    var targetRules: [RemoteConfigParameter.TargetRule] { get }
    var defaultValue: RemoteConfigParameter.Value { get }
}

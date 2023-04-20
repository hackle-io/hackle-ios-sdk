//import Foundation
//
//struct Evaluation: Equatable {
//    let variationId: Variation.Id?
//    let variationKey: Variation.Key
//    let reason: String
//    let config: ParameterConfiguration?
//
//    init(variationId: Variation.Id?, variationKey: Variation.Key, reason: String, config: ParameterConfiguration?) {
//        self.variationId = variationId
//        self.variationKey = variationKey
//        self.reason = reason
//        self.config = config
//    }
//
//    static func ==(lhs: Evaluation, rhs: Evaluation) -> Bool {
//        lhs.variationId == rhs.variationId && lhs.variationKey == rhs.variationKey && lhs.reason == rhs.reason && lhs.config?.id == rhs.config?.id
//    }
//
//    static func of(workspace: Workspace, experiment: Experiment, variationKey: Variation.Key, reason: String) throws -> Evaluation {
//        guard let variation = experiment.getVariationOrNil(variationKey: variationKey) else {
//            return Evaluation(variationId: nil, variationKey: variationKey, reason: reason, config: nil)
//        }
//        return try of(workspace: workspace, variation: variation, reason: reason)
//    }
//
//    static func of(workspace: Workspace, variation: Variation, reason: String) throws -> Evaluation {
//        let parameterConfiguration = try config(workspace: workspace, variation: variation)
//        return Evaluation(variationId: variation.id, variationKey: variation.key, reason: reason, config: parameterConfiguration)
//    }
//
//    private static func config(workspace: Workspace, variation: Variation) throws -> ParameterConfiguration? {
//        guard let parameterConfigurationId = variation.parameterConfigurationId else {
//            return nil
//        }
//
//        guard let parameterConfiguration = workspace.getParameterConfigurationOrNil(parameterConfigurationId: parameterConfigurationId) else {
//            throw HackleError.error("ParameterConfiguration[\(parameterConfigurationId)]")
//        }
//
//        return parameterConfiguration
//    }
//}
//
//
//class RemoteConfigEvaluation {
//    let valueId: Int64?
//    let value: HackleValue
//    let reason: String
//    let properties: [String: Any]
//
//    init(valueId: Int64?, value: HackleValue, reason: String, properties: [String: Any]) {
//        self.valueId = valueId
//        self.value = value
//        self.reason = reason
//        self.properties = properties
//    }
//
//    static func of(valueId: Int64?, value: HackleValue, reason: String, propertiesBuilder: PropertiesBuilder) -> RemoteConfigEvaluation {
//        propertiesBuilder.add("returnValue", value.rawValue)
//        return RemoteConfigEvaluation(valueId: valueId, value: value, reason: reason, properties: propertiesBuilder.build())
//    }
//}

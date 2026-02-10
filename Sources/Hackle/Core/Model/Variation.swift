//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Variation: Sendable {

    typealias Id = Int64
    typealias Key = String

    var id: Id { get }
    var key: Key { get }
    var isDropped: Bool { get }
    var parameterConfigurationId: ParameterConfiguration.Id? { get }
}

final class VariationEntity: Variation, Sendable {

    let id: Id
    let key: Key
    let isDropped: Bool
    let parameterConfigurationId: ParameterConfiguration.Id?

    init(id: Id, key: Key, isDropped: Bool, parameterConfigurationId: ParameterConfiguration.Id?) {
        self.id = id
        self.key = key
        self.isDropped = isDropped
        self.parameterConfigurationId = parameterConfigurationId
    }
}

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
    var parameterConfiguration: ParameterConfiguration? { get }
}

enum VariationKeys {
    static let control: Variation.Key = "A"
}

final class VariationEntity: Variation, @unchecked Sendable {

    let id: Id
    let key: Key
    let isDropped: Bool
    let parameterConfiguration: ParameterConfiguration?

    init(id: Id, key: Key, isDropped: Bool, parameterConfiguration: ParameterConfiguration?) {
        self.id = id
        self.key = key
        self.isDropped = isDropped
        self.parameterConfiguration = parameterConfiguration
    }
}

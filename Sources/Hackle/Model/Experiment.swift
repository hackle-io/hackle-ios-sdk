//
// Created by yong on 2020/12/11.
//

import Foundation


protocol Experiment {
    typealias Id = Int64
    typealias Key = Int64

    var id: Id { get }
    var key: Key { get }

}

protocol Running: Experiment {
    var bucket: Bucket { get }
    func getVariationOrNil(variationId: Variation.Id) -> Variation?
    func getOverriddenVariationOrNil(user: User) -> Variation?
}

protocol Completed: Experiment {
    var winnerVariationKey: Variation.Key { get }
}


class RunningExperimentEntity: Running {

    let id: Id
    let key: Key
    let bucket: Bucket
    let variations: [Variation.Id: Variation]
    let userOverrides: [String: Variation.Id]

    init(id: Id, key: Key, bucket: Bucket, variations: [Variation.Id: Variation], userOverrides: [String: Variation.Id]) {
        self.id = id
        self.key = key
        self.bucket = bucket
        self.variations = variations
        self.userOverrides = userOverrides
    }

    func getVariationOrNil(variationId: Variation.Id) -> Variation? {
        variations[variationId]
    }

    func getOverriddenVariationOrNil(user: User) -> Variation? {
        guard let overriddenVariationId = userOverrides[user.id] else {
            return nil
        }
        return getVariationOrNil(variationId: overriddenVariationId)
    }
}

class CompletedExperimentEntity: Completed {

    let id: Id
    let key: Key
    let winnerVariationKey: Variation.Key

    init(id: Id, key: Key, winnerVariationKey: Variation.Key) {
        self.id = id
        self.key = key
        self.winnerVariationKey = winnerVariationKey
    }
}

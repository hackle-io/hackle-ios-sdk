//
// Created by yong on 2020/12/16.
//

import Foundation
import Mockery
@testable import Hackle

class MockBucket: Mock, Bucket {
    let seed: Int32
    let slotSize: Int32

    init(seed: Int32 = 0, slotSize: Int32 = 10000) {
        self.seed = seed
        self.slotSize = slotSize
        super.init()
    }

    lazy var mockGetSlotOrNil = MockFunction(self, getSlotOrNil)

    func getSlotOrNil(slotNumber: Int) -> Slot? {
        call(mockGetSlotOrNil, args: slotNumber)
    }
}

class MockSlot: Mock, Slot {
    let variationId: Variation.Id

    init(variationId: Variation.Id = 1) {
        self.variationId = variationId
        super.init()
    }

    lazy var mockContains = MockFunction(self, contains)

    func contains(slotNumber: Int) -> Bool {
        call(mockContains, args: slotNumber)
    }
}

class MockExperiment: Mock, Experiment {
    let id: Id
    let key: Key
    let type: ExperimentType

    init(id: Id = 1, key: Key = 1, type: ExperimentType = .abTest) {
        self.id = id
        self.key = key
        self.type = type
        super.init()
    }

    lazy var getVariationByIdOrNilMock: MockFunction<Variation.Id, Variation?> = MockFunction(self, getVariationOrNil)

    func getVariationOrNil(variationId: Variation.Id) -> Variation? {
        call(getVariationByIdOrNilMock, args: variationId)
    }

    lazy var getVariationByKeyOrNilMock: MockFunction<Variation.Key, Variation?> = MockFunction(self, getVariationOrNil)

    func getVariationOrNil(variationKey: Variation.Key) -> Variation? {
        call(getVariationByKeyOrNilMock, args: variationKey)
    }

    lazy var getOverriddenVariationOrNilMock = MockFunction(self, getOverriddenVariationOrNil)

    func getOverriddenVariationOrNil(user: User) -> Variation? {
        call(getOverriddenVariationOrNilMock, args: user)
    }
}

class MockDraftExperiment: MockExperiment, DraftExperiment {
}

class MockRunningExperiment: MockExperiment, RunningExperiment {

    let targetAudiences: [Target]
    let targetRules: [TargetRule]
    let defaultRule: Action

    init(
        id: Id = 42,
        key: Key = 320,
        type: ExperimentType = .abTest,
        targetAudiences: [Target] = [],
        targetRules: [TargetRule] = [],
        defaultRule: Action = ActionEntity(type: .bucket, variationId: nil, bucketId: 1)
    ) {
        self.targetAudiences = targetAudiences
        self.targetRules = targetRules
        self.defaultRule = defaultRule
        super.init(id: id, key: key, type: type)
    }
}

class MockPausedExperiment: MockExperiment, PausedExperiment {

}

class MockCompletedExperiment: MockExperiment, CompletedExperiment {
    let winnerVariation: Variation

    init(
        id: Id = 1,
        key: Key = 1,
        type: ExperimentType = .abTest,
        winnerVariation: Variation
    ) {
        self.winnerVariation = winnerVariation
        super.init(id: id, key: key, type: type)
    }
}

class MockVariation: Mock, Variation {
    var id: Id
    var key: Key
    var isDropped: Bool

    init(id: Id = 42, key: Key = "A", isDropped: Bool = false) {
        self.id = id
        self.key = key
        self.isDropped = isDropped
        super.init()
    }
}

class MockTargetRule: Mock, TargetRule {
    let target: Target
    let action: Action

    init(target: Target = Target(conditions: []), action: Action = ActionEntity(type: .bucket, variationId: nil, bucketId: 1)) {
        self.target = target
        self.action = action
        super.init()
    }
}
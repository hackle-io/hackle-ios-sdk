//
// Created by yong on 2020/12/16.
//

import Foundation
import Mockery
@testable import Hackle

class MockBucket: Mock, Bucket {
    let id: Id
    let seed: Int32
    let slotSize: Int32

    init(id: Id = 1, seed: Int32 = 0, slotSize: Int32 = 10000) {
        self.id = id
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
    let identifierType: String
    let status: ExperimentStatus
    let version: Int
    let variations: [Variation]
    let userOverrides: [User.Id: Variation.Id]
    let segmentOverrides: [TargetRule]
    let targetAudiences: [Target]
    let targetRules: [TargetRule]
    let defaultRule: Action
    let containerId: Container.Id?
    let winnerVariation: Variation?

    init(
        id: Id = 42,
        key: Key = 320,
        type: ExperimentType = .abTest,
        identifierType: String = IdentifierType.id.rawValue,
        status: ExperimentStatus = .running,
        version: Int = 1,
        variations: [Variation] = [],
        userOverrides: [User.Id: Variation.Id] = [:],
        segmentOverrides: [TargetRule] = [],
        targetAudiences: [Target] = [],
        targetRules: [TargetRule] = [],
        defaultRule: Action = ActionEntity(type: .bucket, variationId: nil, bucketId: 1),
        containerId: Container.Id? = nil,
        winnerVariation: Variation? = nil
    ) {
        self.id = id
        self.key = key
        self.type = type
        self.identifierType = identifierType
        self.status = status
        self.version = version
        self.variations = variations
        self.userOverrides = userOverrides
        self.segmentOverrides = segmentOverrides
        self.targetAudiences = targetAudiences
        self.targetRules = targetRules
        self.defaultRule = defaultRule
        self.containerId = containerId
        self.winnerVariation = winnerVariation
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

    func getOverriddenVariationOrNil(user: HackleUser) -> Variation? {
        call(getOverriddenVariationOrNilMock, args: user)
    }
}

class MockVariation: Mock, Variation {
    var id: Id
    var key: Key
    var isDropped: Bool
    var parameterConfigurationId: ParameterConfiguration.Id?


    init(id: Id = 42, key: Key = "A", isDropped: Bool = false, parameterConfigurationId: ParameterConfiguration.Id? = nil) {
        self.id = id
        self.key = key
        self.isDropped = isDropped
        self.parameterConfigurationId = parameterConfigurationId
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

class MockSegment: Mock, Segment {
    let id: Id
    let key: Key
    let type: SegmentType
    let targets: [Target]

    init(id: Id = 42, key: Key = "segment", type: SegmentType = .userId, targets: [Target] = []) {
        self.id = id
        self.key = key
        self.type = type
        self.targets = targets
    }
}

class MockContainer: Mock, Container {
    let id: Id
    let bucketId: Bucket.Id
    let groups: [ContainerGroup]

    init(id: Id = 1, bucketId: Bucket.Id = 2, groups: [ContainerGroup] = []) {
        self.id = id
        self.bucketId = bucketId
        self.groups = groups
    }

    lazy var getGroupOrNilMock = MockFunction(self, getGroupOrNil)

    func getGroupOrNil(containerGroupId: ContainerGroup.Id) -> ContainerGroup? {
        call(getGroupOrNilMock, args: containerGroupId)
    }
}

class MockContainerGroup: Mock, ContainerGroup {
    let id: Id
    let experiments: [Experiment.Id]

    init(id: Id = 1, experiments: [Experiment.Id] = []) {
        self.id = id
        self.experiments = experiments
    }
}

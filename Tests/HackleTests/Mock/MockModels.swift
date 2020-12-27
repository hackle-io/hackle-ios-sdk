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

class MockRunningExperiment: Mock, Running {

    var id: Id
    var key: Key
    var bucket: Bucket

    init(id: Id = 42, key: Key = 320, bucket: Bucket = MockBucket()) {
        self.id = id
        self.key = key
        self.bucket = bucket
        super.init()
    }

    lazy var mockGetVariationOrNil = MockFunction(self, getVariationOrNil)

    func getVariationOrNil(variationId: Variation.Id) -> Variation? {
        call(mockGetVariationOrNil, args: variationId)
    }

    lazy var mockGetOverriddenVariationOrNil = MockFunction(self, getOverriddenVariationOrNil)

    func getOverriddenVariationOrNil(user: User) -> Variation? {
        call(mockGetOverriddenVariationOrNil, args: user)
    }
}

class MockRunning: Mock, Running {

    var id: Id
    var key: Key
    var bucket: Bucket

    init(id: Id = 42, key: Key = 320, bucket: Bucket = MockBucket()) {
        self.id = id
        self.key = key
        self.bucket = bucket
        super.init()
    }

    lazy var mockGetVariationOrNil = MockReference(getVariationOrNil)

    func getVariationOrNil(variationId: Variation.Id) -> Variation? {
        invoke(mockGetVariationOrNil, args: (variationId))
    }

    lazy var mockGetOverriddenVariationOrNil = MockReference(getOverriddenVariationOrNil)

    func getOverriddenVariationOrNil(user: User) -> Variation? {
        invoke(mockGetOverriddenVariationOrNil, args: (user))
    }
}

class MockCompletedExperiment: Mock, Completed {

    var id: Id
    var key: Key
    var winnerVariationKey: Variation.Key

    init(id: Id = 42, key: Key = 320, winnerVariationKey: Variation.Key) {
        self.id = id
        self.key = key
        self.winnerVariationKey = winnerVariationKey
        super.init()
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
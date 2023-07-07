//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Bucketer {
    func bucketing(bucket: Bucket, identifier: String) -> Slot?
}

class DefaultBucketer: Bucketer {

    private let slotNumberCalculator: SlotNumberCalculator

    init(slotNumberCalculator: SlotNumberCalculator = DefaultSlotNumberCalculator()) {
        self.slotNumberCalculator = slotNumberCalculator
    }

    func bucketing(bucket: Bucket, identifier: String) -> Slot? {
        let slotNumber = slotNumberCalculator.calculate(seed: bucket.seed, slotSize: bucket.slotSize, value: identifier)
        return bucket.getSlotOrNil(slotNumber: slotNumber)
    }
}

protocol SlotNumberCalculator {
    func calculate(seed: Int32, slotSize: Int32, value: String) -> Int
}

class DefaultSlotNumberCalculator: SlotNumberCalculator {

    private let hasher: Hasher

    init(hasher: Hasher = Murmur3Hasher()) {
        self.hasher = hasher
    }

    func calculate(seed: Int32, slotSize: Int32, value: String) -> Int {
        let hashValue = hasher.hash(data: value, seed: seed)
        return Int(abs(hashValue) % slotSize)
    }
}

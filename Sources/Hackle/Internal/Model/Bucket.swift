//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Bucket {

    typealias Id = Int64

    var seed: Int32 { get }
    var slotSize: Int32 { get }

    func getSlotOrNil(slotNumber: Int) -> Slot?
}

class BucketEntity: Bucket {

    let seed: Int32
    let slotSize: Int32
    private let slots: [Slot]

    init(seed: Int32, slotSize: Int32, slots: [Slot]) {
        self.seed = seed
        self.slotSize = slotSize
        self.slots = slots
    }

    func getSlotOrNil(slotNumber: Int) -> Slot? {
        slots.first { slot in
            slot.contains(slotNumber: slotNumber)
        }
    }
}

//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Bucket {

    typealias Id = Int64

    var id: Id { get }
    var seed: Int32 { get }
    var slotSize: Int32 { get }

    func getSlotOrNil(slotNumber: Int) -> Slot?
}

class BucketEntity: Bucket {

    let id: Id
    let seed: Int32
    let slotSize: Int32
    private let slots: [Slot]

    init(id: Id, seed: Int32, slotSize: Int32, slots: [Slot]) {
        self.id = id
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

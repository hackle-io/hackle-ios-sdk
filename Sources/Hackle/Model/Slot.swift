//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Slot {
    var variationId: Variation.Id { get }
    func contains(slotNumber: Int) -> Bool
}

class SlotEntity: Slot {

    private let startInclusive: Int
    private let endExclusive: Int
    let variationId: Variation.Id

    init(startInclusive: Int, endExclusive: Int, variationId: Int64) {
        self.startInclusive = startInclusive
        self.endExclusive = endExclusive
        self.variationId = variationId
    }

    func contains(slotNumber: Int) -> Bool {
        startInclusive <= slotNumber && slotNumber < endExclusive
    }
}

//
//  ConcurrentArraySpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/7/25.
//

import Quick
import Nimble
@testable import Hackle

class ConcurrentArraySpecs: QuickSpec {
    override func spec() {
        var array: ConcurrentArray<Int>!

        beforeEach {
            array = ConcurrentArray<Int>()
        }

        it("초기 상태는 비어있다") {
            expect(array.isEmpty).to(beTrue())
            expect(array.size).to(equal(0))
        }

        it("add 후 isEmpty와 size가 정상 동작한다") {
            array.add(1)
            expect(array.isEmpty).to(beFalse())
            expect(array.size).to(equal(1))
        }

        it("take는 FIFO로 요소를 반환하고 제거한다") {
            array.add(1)
            array.add(2)
            expect(array.take()).to(equal(1))
            expect(array.size).to(equal(1))
            expect(array.take()).to(equal(2))
            expect(array.isEmpty).to(beTrue())
        }

        it("takeAll은 모든 요소를 반환하고 array를 비운다") {
            array.add(1)
            array.add(2)
            expect(array.takeAll()).to(equal([1, 2]))
            expect(array.isEmpty).to(beTrue())
        }
    }
}

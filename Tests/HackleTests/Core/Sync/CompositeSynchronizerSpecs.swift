//
//  DelegatingSynchronizerSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/10/02.
//

import Foundation
import Nimble
import Quick
@testable import Hackle

class DelegatingSynchronizerSpecs: QuickSpec {
    override func spec() {

        it("empty") {
            // given
            let sut = CompositeSynchronizer(dispatchQueue: DispatchQueue(label: "test", attributes: .concurrent))
            var count = 0

            // when
            sut.sync {
                count += 1
            }
            Thread.sleep(forTimeInterval: 0.1)

            // then
            expect(count) == 1
        }

        it("wait all delegates") {
            // given
            let dispatchQueue = DispatchQueue(label: "test", attributes: .concurrent)
            let sut = CompositeSynchronizer(dispatchQueue: dispatchQueue)
            let delegate = MockSync()
            sut.add(synchronizer: delegate)
            sut.add(synchronizer: delegate)
            sut.add(synchronizer: delegate)

            // when
            sut.sync {
            }

            Thread.sleep(forTimeInterval: 0.5)

            // then
            expect(delegate.count) == 3
        }

        it("async") {
            // given
            let dispatchQueue = DispatchQueue(label: "test", attributes: .concurrent)
            let sut = CompositeSynchronizer(dispatchQueue: dispatchQueue)
            let delegate = MockSync()
            sut.add(synchronizer: delegate)
            sut.add(synchronizer: delegate)
            sut.add(synchronizer: delegate)
            sut.add(synchronizer: delegate)
            sut.add(synchronizer: delegate)

            // when
            sut.sync {
            }
            Thread.sleep(forTimeInterval: 0.2)

            // then
            expect(delegate.count) == 5
        }
    }
}

private class MockSync: Synchronizer {
    private let lock = ReadWriteLock(label: "test")
    var count = 0

    func sync(completion: @escaping () -> ()) {
        lock.write {
            count += 1
        }
        Thread.sleep(forTimeInterval: 0.1)
        completion()
    }
}

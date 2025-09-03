//
//  DefaultInAppMessageHiddenStorageSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultInAppMessageHiddenStorageSpecs: QuickSpec {
    override func spec() {

        var keyValueRepository: KeyValueRepository!
        var sut: DefaultInAppMessageHiddenStorage!

        beforeEach {
            keyValueRepository = MemoryKeyValueRepository()
            sut = DefaultInAppMessageHiddenStorage(keyValueRepository: keyValueRepository)
        }

        it("데이터가 없는경우 false") {
            let inAppMessage = InAppMessage.create()
            let actual = sut.exist(inAppMessage: inAppMessage, now: Date(timeIntervalSince1970: 0))
            expect(actual) == false
        }

        it("데이터가 있지만 만료시간이 넘은경우 false") {
            let inAppMessage = InAppMessage.create()
            sut.put(inAppMessage: inAppMessage, expireAt: Date(timeIntervalSince1970: 42))
            expect(keyValueRepository.getDouble(key: "1")) == 42

            let actual = sut.exist(inAppMessage: inAppMessage, now: Date(timeIntervalSince1970: 42.1))
            expect(actual) == false
            expect(keyValueRepository.getDouble(key: "1")) == 0
        }

        it("데이터가 있고 만료시간 이내인 경우 true") {
            let inAppMessage = InAppMessage.create()
            sut.put(inAppMessage: inAppMessage, expireAt: Date(timeIntervalSince1970: 42))
            expect(keyValueRepository.getDouble(key: "1")) == 42

            let actual = sut.exist(inAppMessage: inAppMessage, now: Date(timeIntervalSince1970: 42))
            expect(actual) == true
            expect(keyValueRepository.getDouble(key: "1")) == 42
        }
    }
}
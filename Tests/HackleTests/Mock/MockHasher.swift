//
// Created by yong on 2020/12/16.
//

import Foundation
import MockingKit
@testable import Hackle

class MockHasher: Mock, Hasher {

    lazy var mockHash = MockReference(hash)

    func hash(data: String, seed: Int32) -> Int32 {
        call(mockHash, args: (data, seed))
    }
}

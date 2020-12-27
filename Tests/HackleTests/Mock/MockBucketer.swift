//
// Created by yong on 2020/12/11.
//

import Foundation
import Mockery
@testable import Hackle

class MockBucketer: Mock, Bucketer {

    lazy var mockBucketing = MockFunction(self, bucketing)

    func bucketing(bucket: Bucket, user: User) -> Slot? {
        call(mockBucketing, args: (bucket, user))
    }
}

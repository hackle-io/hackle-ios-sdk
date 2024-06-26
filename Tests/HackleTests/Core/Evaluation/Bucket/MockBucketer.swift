//
// Created by yong on 2020/12/11.
//

import Foundation
import Mockery
@testable import Hackle

class MockBucketer: Mock, Bucketer {

    lazy var bucketingMock = MockFunction(self, bucketing)

    func bucketing(bucket: Bucket, identifier: String) -> Slot? {
        call(bucketingMock, args: (bucket, identifier))
    }
}

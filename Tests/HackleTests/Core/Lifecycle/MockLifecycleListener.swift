import Foundation
import MockingKit
@testable import Hackle

class MockLifecycleListener: Mock, ViewLifecycleListener {
    lazy var onLifecycleMock = MockFunction(self, onLifecycle)

    func onLifecycle(lifecycle: ViewLifecycle, timestamp: Date) {
        call(onLifecycleMock, args: (lifecycle, timestamp))
    }
}

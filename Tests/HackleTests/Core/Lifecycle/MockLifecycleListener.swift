import Foundation
import Mockery
@testable import Hackle

class MockLifecycleListener: Mock, LifecycleListener {
    lazy var onLifecycleMock = MockFunction(self, onLifecycle)

    func onLifecycle(lifecycle: Lifecycle, timestamp: Date) {
        call(onLifecycleMock, args: (lifecycle, timestamp))
    }
}

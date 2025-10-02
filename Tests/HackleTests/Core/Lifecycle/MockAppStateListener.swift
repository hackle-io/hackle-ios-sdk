import Foundation
import MockingKit
@testable import Hackle

class MockApplicationLifecycleListener: Mock, ApplicationLifecycleListener {

    lazy var onForegroundMock = MockFunction(self, onForeground)
    lazy var onBackgroundMock = MockFunction(self, onBackground)

    func onForeground(timestamp: Date, isFromBackground: Bool) {
        call(onForegroundMock, args: (timestamp, isFromBackground))
    }

    func onBackground(timestamp: Date) {
        call(onBackgroundMock, args: (timestamp))
    }
}

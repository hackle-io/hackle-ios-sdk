import Foundation
import UIKit
import MockingKit
@testable import Hackle

class MockApplicationLifecycleListener: Mock, ApplicationLifecycleListener {

    lazy var onForegroundMock = MockFunction(self, onForeground)
    lazy var onBackgroundMock = MockFunction(self, onBackground)

    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        call(onForegroundMock, args: (topViewController, timestamp, isFromBackground))
    }

    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        call(onBackgroundMock, args: (topViewController, timestamp))
    }
}

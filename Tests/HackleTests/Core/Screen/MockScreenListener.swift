import Foundation
import MockingKit
@testable import Hackle

class MockScreenListener: Mock, ScreenListener {

    lazy var onScreenStartedMock = MockFunction(self, onScreenStarted)

    func onScreenStarted(previousScreen: Screen?, currentScreen: Screen, user: User, timestamp: Date) {
        call(onScreenStartedMock, args: (previousScreen, currentScreen, user, timestamp))
    }

    lazy var onScreenEndedMock = MockFunction(self, onScreenEnded)

    func onScreenEnded(screen: Screen, user: User, timestamp: Date) {
        call(onScreenEndedMock, args: (screen, user, timestamp))
    }
}

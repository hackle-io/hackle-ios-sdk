import Foundation
import Mockery
@testable import Hackle

class MockScreeManager: Mock, ScreenManager {

    var currentScreen: Screen?

    init(currentScreen: Screen? = nil) {
        self.currentScreen = currentScreen
    }
    
    lazy var setCurrentScreenMock = MockFunction(self, setCurrentScreen as (Screen, Date) -> ())
    
    func setCurrentScreen(screen: Screen, timestamp: Date) {
        self.currentScreen = screen
        call(setCurrentScreenMock, args: (screen, timestamp))
    }
}

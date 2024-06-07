import Foundation
import Mockery
@testable import Hackle

class MockScreeManager: ScreenManager {

    var currentScreen: Screen?

    init(currentScreen: Screen? = nil) {
        self.currentScreen = currentScreen
    }
}

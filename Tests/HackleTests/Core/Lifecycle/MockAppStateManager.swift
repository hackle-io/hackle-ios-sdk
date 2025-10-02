import Foundation
@testable import Hackle

class MockAppStateManager: AppStateManager {
    var currentState: ApplicationState

    init(currentState: ApplicationState = .background) {
        self.currentState = currentState
    }
}

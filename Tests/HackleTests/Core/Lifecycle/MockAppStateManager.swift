import Foundation
@testable import Hackle

class MockAppStateManager: AppStateManager {
    var currentState: AppState

    init(currentState: AppState = .background) {
        self.currentState = currentState
    }
}

import Foundation
@testable import Hackle

class MockApplicationLifecycleManager: ApplicationLifecycleManager {
    var currentState: ApplicationState

    init(currentState: ApplicationState = .background) {
        self.currentState = currentState
    }

    func addListener(listener: ApplicationLifecycleListener) {
        // Mock implementation
    }
}

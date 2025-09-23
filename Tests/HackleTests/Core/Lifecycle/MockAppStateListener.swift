import Foundation
import MockingKit
@testable import Hackle

class MockAppStateListener: Mock, AppStateListener {

    lazy var onStateMock = MockFunction(self, onState)

    func onState(state: AppState, timestamp: Date) {
        call(onStateMock, args: (state, timestamp))
    }
}

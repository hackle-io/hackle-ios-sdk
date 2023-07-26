import Foundation
@testable import Hackle


class MockInAppMessageEventTriggerDeterminer: InAppMessageEventTriggerDeterminer {

    var isMatch: Bool

    init(isMatch: Bool = false) {
        self.isMatch = isMatch
    }

    func isTriggerTarget(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> Bool {
        isMatch
    }
}

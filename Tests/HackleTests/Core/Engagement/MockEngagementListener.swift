import Foundation
import MockingKit
@testable import Hackle

class MockEngagementListener: Mock, EngagementListener {
    lazy var onEngagementMock = MockFunction(self, onEngagement)

    func onEngagement(engagement: Engagement, user: User, timestamp: Date) {
        call(onEngagementMock, args: (engagement, user, timestamp))
    }
}

import Foundation
@testable import Hackle

@MainActor
final class MockUserActivityHandler: UserActivityHandler {
    var sceneSupported = false
    var applicationResult: Bool? = nil
    private(set) var sceneUrls: [URL] = []
    private(set) var applicationUrls: [URL] = []

    nonisolated init() {}

    var isContinueInApplicationSupported: Bool {
        applicationResult != nil
    }

    func continueInScene(_ userActivity: NSUserActivity) -> Bool {
        guard sceneSupported else {
            return false
        }
        if let url = userActivity.webpageURL {
            sceneUrls.append(url)
        }
        return true
    }

    func continueInApplication(_ userActivity: NSUserActivity) -> Bool? {
        guard let result = applicationResult else {
            return nil
        }
        if let url = userActivity.webpageURL {
            applicationUrls.append(url)
        }
        return result
    }
}

import Foundation
import MockingKit
@testable import Hackle

class MockHttpWorkspaceConfigFetcher: Mock, HttpWorkspaceConfigFetcher {

    private let returns: [Any?]
    private var count = 0

    init(returns: [Any?]) {
        self.returns = returns
    }

    lazy var fetchIfModifiedRef = MockFunction(self, fetchIfModifiedStub)

    private func fetchIfModifiedStub(lastModified: String?) {
    }

    func fetchIfModified(lastModified: String?) async throws -> WorkspaceConfigContext? {
        call(fetchIfModifiedRef, args: lastModified)

        let value = returns[count]
        count += 1

        switch value {
        case let context as WorkspaceConfigContext:
            return context
        case let error as Error:
            throw error
        default:
            return nil
        }
    }
}

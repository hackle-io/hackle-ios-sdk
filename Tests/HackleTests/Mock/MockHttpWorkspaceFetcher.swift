import Foundation
import MockingKit
@testable import Hackle

class MockHttpWorkspaceFetcher: Mock, HttpWorkspaceFetcher {

    private let returns: [Any?]
    private var count = 0

    init(returns: [Any?]) {
        self.returns = returns
    }

    lazy var fetchIfModifiedRef = MockFunction<String?, Void>(self) { _ in }

    func fetchIfModified(lastModified: String?) async throws -> WorkspaceConfigResponse? {
        call(fetchIfModifiedRef, args: lastModified)

        let value = returns[count]
        count += 1

        switch value {
        case let config as WorkspaceConfigResponse:
            return config
        case let error as Error:
            throw error
        default:
            return nil
        }
    }
}

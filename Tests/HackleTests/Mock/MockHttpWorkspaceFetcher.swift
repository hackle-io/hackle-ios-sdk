import Foundation
import MockingKit
@testable import Hackle

class MockHttpWorkspaceFetcher: Mock, HttpWorkspaceFetcher {

    private let returns: [Any?]
    private var count = 0

    init(returns: [Any?]) {
        self.returns = returns
    }
    
    lazy var fetchIfModifiedRef = MockFunction(self, fetchIfModified)
    func fetchIfModified(lastModified: String?, completion: @escaping (Result<WorkspaceConfig?, Error>) -> ()) {
        call(fetchIfModifiedRef, args: (lastModified, completion))
        
        let value = returns[count]
        count += 1

        switch value {
        case let config as WorkspaceConfig:
            completion(.success(config))
            break
        case let error as Error:
            completion(.failure(error))
            break
        default:
            completion(.success(nil))
        }
    }
}

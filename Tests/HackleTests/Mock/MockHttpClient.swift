//
// Created by yong on 2020/12/21.
//

import Foundation
import MockingKit
@testable import Hackle

class MockHttpClient: Mock, HttpClient {
    lazy var executeMock = MockFunction(self, execute as (HttpRequest, @escaping @Sendable (HttpResponse) -> ()) -> Void)

    func execute(request: HttpRequest, completion: @escaping @Sendable (HttpResponse) -> ()) {
        call(executeMock, args: (request, completion))
    }

    func execute(request: HttpRequest, timeout: TimeInterval, completion: @escaping @Sendable (HttpResponse) -> Void) {
        call(executeMock, args: (request, completion))
    }

}

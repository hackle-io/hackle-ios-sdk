//
// Created by yong on 2020/12/21.
//

import Foundation
import Mockery
@testable import Hackle

class MockHttpClient: Mock, HttpClient {

    lazy var executeMock = MockFunction(self, execute)

    func execute(request: HttpRequest, completion: @escaping (HttpResponse) -> ()) {
        call(executeMock, args: (request, completion))
    }
}

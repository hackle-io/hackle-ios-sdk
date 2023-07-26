import Foundation
import Mockery
@testable import Hackle

class MockUrlHandler: Mock, UrlHandler {

    lazy var openMock = MockFunction(self, open)

    func open(url: URL) {
        call(openMock, args: url)
    }
}

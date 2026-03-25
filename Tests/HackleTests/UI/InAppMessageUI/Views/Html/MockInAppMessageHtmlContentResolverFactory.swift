import Foundation
@testable import Hackle
import MockingKit

class MockInAppMessageHtmlContentResolverFactory: Mock, InAppMessageHtmlContentResolverFactory {
    lazy var getMock = MockFunction(self, get)
    func get(resourceType: InAppMessage.HtmlResourceType) throws -> InAppMessageHtmlContentResolver {
        return call(getMock, args: resourceType)
    }
}

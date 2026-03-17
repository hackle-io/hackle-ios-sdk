import Foundation
@testable import Hackle
import MockingKit
import UIKit

class MockInAppMessageViewProvider: Mock, InAppMessageViewProvider {
    var currentView: InAppMessageView?

    lazy var getViewMock = MockFunction(self, getView)
    func getView(viewId: String) -> InAppMessageView? {
        return call(getViewMock, args: viewId)
    }
}

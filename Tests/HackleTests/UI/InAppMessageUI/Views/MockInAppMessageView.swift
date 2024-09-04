import Foundation
import UIKit
@testable import Hackle

class MockInAppMessageView: UIView, InAppMessageView {

    let context: InAppMessagePresentationContext
    var presented: Bool = false

    init(context: InAppMessagePresentationContext = InAppMessage.context(), presented: Bool = false) {
        self.context = context
        self.presented = presented
        super.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func willTransition(orientation: InAppMessage.Orientation) {

    }

    func present() {
        presented = true
    }

    func dismiss() {
        presented = false
    }
}

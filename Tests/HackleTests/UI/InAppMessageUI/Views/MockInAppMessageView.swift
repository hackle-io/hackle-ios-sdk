import Foundation
@testable import Hackle
import UIKit

class MockInAppMessageView: UIView, InAppMessageView {
    let id: String
    let context: InAppMessagePresentationContext
    var presented: Bool = false

    init(
        id: String = UUID().uuidString,
        context: InAppMessagePresentationContext = InAppMessage.context(),
        presented: Bool = false
    ) {
        self.id = id
        self.context = context
        self.presented = presented
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        presented = true
    }

    func dismiss() {
        presented = false
    }
}

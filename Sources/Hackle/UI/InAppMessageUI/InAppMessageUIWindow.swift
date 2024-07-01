import Foundation
import UIKit

extension HackleInAppMessageUI {
    class Window: UIWindow {

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            guard let view = super.hitTest(point, with: event) else {
                return nil
            }
            let isInAppMessageView = view is InAppMessageView || view.responders.lazy.contains(where: { $0 is InAppMessageView })
            return isInAppMessageView ? view : nil
        }

        var messageViewController: ViewController? {
            rootViewController as? ViewController
        }
    }
}

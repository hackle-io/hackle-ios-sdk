import Foundation
import UIKit

extension HackleInAppMessageUI {

    func createMessageView(context: InAppMessagePresentationContext) -> InAppMessageView? {
        switch (context.message.layout.displayType, context.message.layout.layoutType) {
        case (.none, _):
            return nil
        case (.modal, _):
            let attributes = ModalView.Attributes(orientation: InAppMessage.Orientation(UIUtils.interfaceOrientation))
            return ModalView(context: context, attributes: attributes)
        case (.banner, .imageText), (.banner, .textOnly):
            guard let alignment = context.message.layout.alignment else {
                Log.error("Not found Alignment in banner in-app message [\(context.inAppMessage.id)]")
                return nil
            }
            return BannerView(context: context, alignment: alignment, attributes: .defaults)
        case (.banner, .image):
            guard let alignment = context.message.layout.alignment else {
                Log.error("Not found Alignment in banner in-app message [\(context.inAppMessage.id)]")
                return nil
            }
            return BannerImageView(context: context, alignment: alignment, attributes: .defaults)
        case (.bottomSheet, _):
            return BottomSheetView(context: context)
        default:
            Log.error("Failed to create InAppMessageView [\(context.message.layout.displayType), \(context.message.layout.layoutType)]")
            return nil
        }
    }

    func createWindow(viewController: ViewController) -> Window {
        let window: Window
        if #available(iOS 13.0, *), let windowScene = UIUtils.activeWindowScene {
            window = Window(windowScene: windowScene)
        } else {
            window = Window(frame: UIScreen.main.bounds)
        }
        window.accessibilityViewIsModal = true
        window.windowLevel = .normal
        window.rootViewController = viewController
        return window
    }
}

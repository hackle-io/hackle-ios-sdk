//
//  HackleInAppMessageUI.swift
//  Hackle
//
//  Created by yong on 2023/06/05.
//

import Foundation
import UIKit

@objc(HackleInAppMessageUI)
class HackleInAppMessageUI: NSObject, InAppMessagePresenter, InAppMessageViewProvider, @unchecked Sendable {
    let clock: Clock
    let eventProcessor: InAppMessageViewEventProcessor
    let htmlContentResolverFactory: InAppMessageHtmlContentResolverFactory

    init(
        clock: Clock,
        eventProcessor: InAppMessageViewEventProcessor,
        htmlContentResolverFactory: InAppMessageHtmlContentResolverFactory
    ) {
        self.clock = clock
        self.eventProcessor = eventProcessor
        self.htmlContentResolverFactory = htmlContentResolverFactory
        super.init()
    }

    @MainActor var window: Window?
    var delegate: HackleInAppMessageDelegate?

    @MainActor var currentView: InAppMessageView? {
        window?.messageViewController?.messageView
    }

    @MainActor func getView(viewId: String) -> InAppMessageView? {
        guard let view = currentView, view.id == viewId else {
            return nil
        }
        return view
    }

    func present(context: InAppMessagePresentationContext) async -> InAppMessagePresentResponse {
        await presentNow(context: context)
    }

    @MainActor private func presentNow(context: InAppMessagePresentationContext) -> InAppMessagePresentResponse {
        guard applicationActive() else {
            return InAppMessagePresentResponse.of(code: .activityNotFound, context: context)
        }
        guard checkRootViewController() else {
            return InAppMessagePresentResponse.of(code: .activityNotFound, context: context)
        }
        guard noMessagePresented() else {
            return InAppMessagePresentResponse.of(code: .alreadyPresented, context: context)
        }
        guard orientationSupported(context: context) else {
            return InAppMessagePresentResponse.of(code: .unsupportedOrientation, context: context)
        }

        // Message View
        // 미노출 AB 등 view가 생성되지 않는 경우에도 present 한 것으로 간주한다
        guard let messageView = createMessageView(context: context) else {
            return InAppMessagePresentResponse.of(code: .present, context: context)
        }

        // ViewController
        let viewController = ViewController(
            ui: self,
            context: context,
            messageView: messageView
        )

        // Window
        let window = createWindow(viewController: viewController)
        self.window = window

        // Display
        if #available(iOS 15.0, *) {
            UIView.animate(withDuration: 0.25) {
                window.isHidden = false
            }
        } else {
            window.isHidden = false
        }
        return InAppMessagePresentResponse.of(code: .present, context: context)
    }

    // 백그라운드에서는 노출하지 않는다. checkRootViewController는 activeWindowScene의 fallback 때문에
    // 백그라운드에서도 통과하므로 앱 상태를 직접 확인한다. android는 deliver 단계에서 ACTIVITY_INACTIVE로 끊는다.
    @MainActor private func applicationActive() -> Bool {
        guard let application = UIUtils.application else {
            // app extension 등 조회 불가 환경에서는 기존 동작을 유지한다
            return true
        }
        return application.applicationState == .active
    }

    @MainActor private func checkRootViewController() -> Bool {
        UIUtils.keyWindow?.rootViewController != nil
    }

    @MainActor private func noMessagePresented() -> Bool {
        currentView == nil
    }

    @MainActor private func orientationSupported(context: InAppMessagePresentationContext) -> Bool {
        context.inAppMessage.supports(orientation: UIUtils.interfaceOrientation)
    }
}

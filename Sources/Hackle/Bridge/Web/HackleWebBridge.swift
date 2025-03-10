import Foundation
import WebKit

private let identifier = "/* Hackle App JavaScript Controller */"
private let name = "_hackleApp"

extension WKWebView {

    private enum ReservedKey: String {
        case getAppSdkKey = "getAppSdkKey"
        case getAppMode = "getAppMode"
        case getInvocationType = "getInvocationType"
    }

    private struct AssociatedKeys {
        static var _uiDelegate: UInt8 = 0
    }

    private var _uiDelegate: HackleUIDelegate? {
        get {
            objc_getAssociatedObject(
                self,
                &AssociatedKeys._uiDelegate
            ) as? HackleUIDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys._uiDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private func bridgeScript() -> WKUserScript {
        let source = """
                     window.\(name) = {
                         \(ReservedKey.getAppSdkKey): function() {
                             return '\(Hackle.app()?.sdk.key ?? "")'
                         },
                         \(ReservedKey.getAppMode): function() {
                             return '\(Hackle.app()?.mode.description ?? "")'
                         },
                         \(ReservedKey.getInvocationType): function() {
                             return 'prompt'
                         }
                     }
                     """
        return WKUserScript(
            source: "\(identifier)\n\(source)",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }

    func prepareForHackleWebBridge(app: HackleApp, uiDelegate: WKUIDelegate? = nil) {
        let userContentController = configuration.userContentController
        let userScripts = userContentController.userScripts.filter {
            !$0.source.hasPrefix(identifier)
        }
        userContentController.removeAllUserScripts()
        userContentController.addUserScript(bridgeScript())
        userScripts.forEach {
            userContentController.addUserScript($0)
        }

        let uiDelegate = uiDelegate ?? self.uiDelegate
        _uiDelegate = HackleUIDelegate(app: app, uiDelegate: uiDelegate)
        self.uiDelegate = _uiDelegate
    }
}

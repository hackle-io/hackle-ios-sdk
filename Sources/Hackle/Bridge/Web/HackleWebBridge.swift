import Foundation
import WebKit

private let identifier = "/* Hackle App JavaScript Controller */"
private let name = "_hackleApp"

public extension WKWebView {
    
    private struct AssociatedKeys {
        static var _uiDelegate: UInt8 = 0
    }
    
    private enum ReservedKey: String {
        case getAppSdkKey = "getAppSdkKey"
        case getInvocationType = "getInvocationType"
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
    
    func bridgeScript() -> WKUserScript {
        let source = """
            window.\(name) = {
                \(ReservedKey.getAppSdkKey): function() {
                    return '\(Hackle.app()?.sdk.key ?? "")'
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
    
    func prepareForHackleWebBridge(uiDelegate: WKUIDelegate? = nil) {
        let userContentController = configuration.userContentController
        let userScripts = userContentController.userScripts.filter {
            !$0.source.hasPrefix(identifier)
        }
        userContentController.removeAllUserScripts()
        userContentController.addUserScript(bridgeScript())
        userScripts.forEach { userContentController.addUserScript($0) }
        
        let uiDelegate = self.uiDelegate ?? uiDelegate
        if _uiDelegate == nil {
            _uiDelegate = HackleUIDelegate(uiDelegate: uiDelegate)
        }
        self.uiDelegate = _uiDelegate
    }
}

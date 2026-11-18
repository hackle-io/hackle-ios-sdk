import Foundation

final class InAppMessagePresentResponse: Sendable {

    let code: Code
    let context: InAppMessagePresentationContext

    init(code: Code, context: InAppMessagePresentationContext) {
        self.code = code
        self.context = context
    }

    enum Code {
        case present
        case applicationNotActive
        case rootViewControllerNotFound
        case alreadyPresented
        case unsupportedOrientation
        case inProgress
        case exception
    }
}

extension InAppMessagePresentResponse: CustomStringConvertible {

    static func of(code: Code, context: InAppMessagePresentationContext) -> InAppMessagePresentResponse {
        return InAppMessagePresentResponse(code: code, context: context)
    }

    var description: String {
        "InAppMessagePresentResponse(code: \(code), dispatchId: \(context.dispatchId), inAppMessage: \(context.inAppMessage), displayType: \(context.message.layout.displayType), layoutType: \(context.message.layout.layoutType))"
    }
}

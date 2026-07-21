import Foundation

class InAppMessagePresentResponse {

    let code: Code
    let context: InAppMessagePresentationContext

    init(code: Code, context: InAppMessagePresentationContext) {
        self.code = code
        self.context = context
    }

    // inProgress/exception은 iOS에서는 도달하지 않지만 플랫폼 간 코드 어휘 통일을 위해 유지한다
    enum Code {
        case present
        case activityNotFound
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

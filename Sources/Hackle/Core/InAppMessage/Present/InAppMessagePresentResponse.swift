import Foundation

class InAppMessagePresentResponse {

    let dispatchId: String
    let context: InAppMessagePresentationContext

    init(dispatchId: String, context: InAppMessagePresentationContext) {
        self.dispatchId = dispatchId
        self.context = context
    }
}

extension InAppMessagePresentResponse: CustomStringConvertible {

    static func of(request: InAppMessagePresentRequest, context: InAppMessagePresentationContext) -> InAppMessagePresentResponse {
        return InAppMessagePresentResponse(dispatchId: request.dispatchId, context: context)
    }

    var description: String {
        "InAppMessagePresentResponse(dispatchId: \(dispatchId), context: \(context))"
    }
}

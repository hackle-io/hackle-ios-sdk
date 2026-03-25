import Foundation

protocol InvocationProcessor {
    func process(request: InvocationRequest) -> InvocationResponse<Any>
}

class DefaultInvocationProcessor: InvocationProcessor {
    private let handlerFactory: InvocationHandlerFactory

    init(handlerFactory: InvocationHandlerFactory) {
        self.handlerFactory = handlerFactory
    }

    func process(request: InvocationRequest) -> InvocationResponse<Any> {
        do {
            let handler = try handlerFactory.get(command: request.command)
            return try handler.handle(request: request)
        } catch {
            Log.error("Failed to process Invocation: \(String(describing: error))")
            return .error(error: error)
        }
    }
}

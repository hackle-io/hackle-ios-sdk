import Foundation

protocol InvocationHandler {
    associatedtype T
    func invoke(request: InvocationRequest) throws -> InvocationResponse<T>
}

extension InvocationHandler {
    func handle(request: InvocationRequest) throws -> InvocationResponse<Any> {
        let response = try invoke(request: request)
        return InvocationResponse<Any>(isSuccess: response.isSuccess, message: response.message, data: response.data)
    }
}

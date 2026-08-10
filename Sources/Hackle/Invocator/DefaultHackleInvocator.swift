import Foundation

class DefaultHackleInvocator: NSObject, HackleInvocator {
    private let processor: InvocationProcessor

    init(processor: InvocationProcessor) {
        self.processor = processor
    }

    func isInvocableString(string: String) -> Bool {
        return InvocationRequest.isInvocable(string: string)
    }

    func invoke(string: String, completionHandler: (String?) -> Void) {
        let result = invoke(string: string)
        completionHandler(result)
    }

    func invokeAsync(string: String, completionHandler: @escaping (String?) -> Void) {
        let response = response(string: string)
        let json = response.toJsonString()
        guard let task = response.task else {
            completionHandler(json)
            return
        }
        task.onComplete(queue: .main) {
            completionHandler(json)
        }
    }

    func invoke(string: String) -> String {
        return response(string: string).toJsonString()
    }

    private func response(string: String) -> InvocationResponse<Any> {
        do {
            let request = try InvocationRequest.parse(string: string)
            return processor.process(request: request)
        } catch {
            return InvocationResponse<Any>.error(error: error)
        }
    }
}

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

    func invoke(string: String) -> String {
        do {
            let request = try InvocationRequest.parse(string: string)
            let response = processor.process(request: request)
            return response.toJsonString()
        } catch {
            return InvocationResponse<Any>.error(error: error).toJsonString()
        }
    }
}

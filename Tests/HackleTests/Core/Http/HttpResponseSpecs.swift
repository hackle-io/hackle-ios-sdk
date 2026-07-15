import Foundation
import Quick
import Nimble
@testable import Hackle

class HttpResponseSpecs: QuickSpec {
    override class func spec() {

        func response(statusCode: Int, error: Error? = nil) -> HttpResponse {
            let request = HttpRequest.get(url: URL(string: "https://api.hackle.io")!)
            return HttpResponse(
                request: request,
                data: nil,
                urlResponse: HTTPURLResponse(url: request.url, statusCode: statusCode, httpVersion: nil, headerFields: nil),
                error: error
            )
        }

        it("isNoContent는 204에서만 true다") {
            expect(response(statusCode: 204).isNoContent) == true
            expect(response(statusCode: 200).isNoContent) == false
        }

        it("에러가 있으면 isNoContent는 false다") {
            expect(response(statusCode: 204, error: HackleError.error("e")).isNoContent) == false
        }
    }
}

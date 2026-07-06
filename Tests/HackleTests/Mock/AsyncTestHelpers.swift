import Nimble
@testable import Hackle

/// async 작업을 waitUntil로 감싸 완료까지 대기하고 결과를 Result로 반환한다.
func awaitResult<T>(timeout: NimbleTimeInterval = .seconds(1), _ operation: @escaping () async throws -> T) -> Result<T, Error> {
    var result: Result<T, Error>?
    waitUntil(timeout: timeout) { done in
        Task {
            do {
                result = .success(try await operation())
            } catch {
                result = .failure(error)
            }
            done()
        }
    }
    return result ?? .failure(HackleError.error("awaitResult timed out"))
}

/// async 작업을 waitUntil로 감싸 완료까지 대기한다. 발생한 에러는 무시한다.
func awaitCompletion(timeout: NimbleTimeInterval = .seconds(1), _ operation: @escaping () async throws -> Void) {
    _ = awaitResult(timeout: timeout, operation)
}

import Nimble
@testable import Hackle

/// async 작업을 waitUntil로 감싸 완료까지 대기하고 결과를 Result로 반환한다.
///
/// timeout은 실제 대기 방식이 아니라 안전 상한이다. done()이 async 작업 완료 즉시 호출되므로
/// 정상 케이스는 timeout과 무관하게 곧바로 반환한다. 다만 CI(느린 macos runner + `-test-iterations`로
/// 전체 스위트를 여러 번 반복 + 무거운 race 스펙과의 CPU/스레드풀 경합)에서는 async Task 스케줄링이
/// 수 초 지연될 수 있어, 상한이 너무 짧으면 완료 전 false timeout이 난다. 넉넉하게 잡아 flaky를 방지한다.
func awaitResult<T>(timeout: NimbleTimeInterval = .seconds(10), _ operation: @escaping () async throws -> T) -> Result<T, Error> {
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
/// timeout 의미는 awaitResult 참고 (CI 부하 대비 안전 상한).
func awaitCompletion(timeout: NimbleTimeInterval = .seconds(10), _ operation: @escaping () async throws -> Void) {
    _ = awaitResult(timeout: timeout, operation)
}

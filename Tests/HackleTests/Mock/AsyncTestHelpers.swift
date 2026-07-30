@testable import Hackle

/// async 작업을 직접 await 해 완료까지 대기하고 결과를 Result로 반환한다.
///
/// 반드시 async 컨텍스트(AsyncSpec)에서 호출한다. 이전에는 동기 `waitUntil` 안에서 `Task`를 띄우는
/// 브리지였는데, 이 방식은 협조 스레드 풀이 극소수인 환경(CI 러너)에서 스케줄링 기아로 hang을 유발했다.
/// AsyncSpec에서 직접 await 하면 메인 스레드를 블로킹하지 않고 브리지 자체가 사라진다.
func awaitResult<T>(_ operation: () async throws -> T) async -> Result<T, Error> {
    do {
        return .success(try await operation())
    } catch {
        return .failure(error)
    }
}

/// async 작업을 직접 await 해 완료까지 대기한다. 발생한 에러는 무시한다.
func awaitCompletion(_ operation: () async throws -> Void) async {
    _ = await awaitResult(operation)
}

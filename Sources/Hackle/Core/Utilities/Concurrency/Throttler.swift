import Foundation


protocol Throttler {
    /// accept 또는 reject 중 정확히 하나를 execute 반환 전에 동기적으로 호출해야 한다.
    /// (HackleAppCore.fetch가 이 동기 호출 계약에 의존한다)
    func execute(accept: @escaping () -> (), reject: @escaping () -> ())
}


final class DefaultThrottler: Throttler, @unchecked Sendable {
    private let limiter: ThrottleLimiter

    init(limiter: ThrottleLimiter) {
        self.limiter = limiter
    }

    func execute(accept: @escaping () -> (), reject: @escaping () -> ()) {
        if limiter.tryAcquire() {
            accept()
        } else {
            reject()
        }
    }
}

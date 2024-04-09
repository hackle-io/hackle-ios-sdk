import Foundation


protocol Throttler {
    func execute(accept: @escaping () -> (), reject: @escaping () -> ())
}


class DefaultThrottler: Throttler {
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

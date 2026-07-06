@testable import Hackle

/// N개의 async 호출자가 모두 도착할 때까지 비블로킹으로 대기시키는 배리어.
/// cooperative pool 스레드 수와 무관하게 동작(await 기반, blocking 아님).
///
/// - Important: `wait()`을 호출하는 개수는 반드시 `count`와 정확히 일치해야 한다.
///   호출 횟수가 `count`보다 적으면 이미 도착한 모든 호출자가 영구히 suspend된다.
///   타임아웃/탈출 경로가 없으므로, 호출 수 불일치는 (의도적으로) 테스트 데드락으로 나타난다.
actor Barrier {
    private let count: Int
    private var arrived = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(count: Int) {
        self.count = count
    }

    /// 도착 카운트를 1 증가시키고, `count`에 도달하면 대기 중이던 모든 호출자를 깨운다.
    /// 그렇지 않으면 이 호출자 자신도 대기열에 등록되어 suspend된다.
    ///
    /// - Warning: `wait()` 호출 총 횟수가 `count`에 도달하지 못하면 이 함수는 영원히 반환하지 않는다.
    func wait() async {
        arrived += 1
        if arrived >= count {
            for waiter in waiters {
                waiter.resume()
            }
            waiters.removeAll()
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
}

/// sync() 진입 시 배리어에 도착·대기하는 결정적 테스트 synchronizer.
/// CompositeSynchronizer가 child들을 동시에 dispatch하면 모두 배리어를 통과하고,
/// 순차 await로 회귀하면 첫 child가 배리어에서 영구 대기 → 상위 호출이 타임아웃된다.
class BarrierSynchronizer: Synchronizer {
    private let barrier: Barrier
    private(set) var synced = false

    init(barrier: Barrier) {
        self.barrier = barrier
    }

    func sync() async throws {
        await barrier.wait()
        synced = true
    }
}

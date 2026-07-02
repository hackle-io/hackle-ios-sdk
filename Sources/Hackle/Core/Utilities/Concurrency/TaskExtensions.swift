import Foundation

extension Task where Success == Void, Failure == Never {
    /// 비동기 파트 완료 후 지정 큐에서 completion을 호출한다.
    /// public completion API가 async 코어를 감쌀 때 사용하는 유일한 콜백 브리지.
    func onComplete(queue: DispatchQueue, _ completion: @escaping () -> Void) {
        Task<Void, Never> {
            await self.value
            queue.async {
                completion()
            }
        }
    }
}

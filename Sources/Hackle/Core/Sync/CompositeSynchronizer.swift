import Foundation

class CompositeSynchronizer: Synchronizer {

    private let dispatchQueue: DispatchQueue
    private var synchronizers: [Synchronizer] = []

    init(dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
    }

    func add(synchronizer: Synchronizer) {
        self.synchronizers.append(synchronizer)
        Log.debug("Synchronizer added [\(synchronizer)]")
    }

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        let dispatchGroup = DispatchGroup()
        for synchronizer in synchronizers {
            dispatchGroup.enter()
            dispatchQueue.async {
                synchronizer.sync { result in
                    dispatchGroup.leave()
                    if case .failure(let error) = result {
                        Log.error("Failed to sync: \(error)")
                    }
                }
            }
        }
        dispatchGroup.notify(queue: dispatchQueue) {
            completion(.success(()))
        }
    }
}

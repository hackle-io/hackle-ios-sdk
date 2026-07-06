import Foundation

class CompositeSynchronizer: Synchronizer {

    private var synchronizers: [Synchronizer] = []

    func add(synchronizer: Synchronizer) {
        self.synchronizers.append(synchronizer)
        Log.debug("Synchronizer added [\(synchronizer)]")
    }

    func sync() async throws {
        await withTaskGroup(of: Void.self) { group in
            for synchronizer in synchronizers {
                group.addTask {
                    await synchronizer.safeSync()
                }
            }
        }
    }
}

//
// Created by yong on 2020/12/11.
//

import Foundation

protocol WorkspaceFetcher {
    func fetch() -> Workspace?
    func initialize(completion: @escaping () -> ())
}

class PollingWorkspaceFetcher: WorkspaceFetcher, AppStateChangeListener {

    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.PollingWorkspaceFetcher.Lock")

    private let httpWorkspaceFetcher: HttpWorkspaceFetcher
    private let pollingScheduler: Scheduler
    private let pollingInterval: TimeInterval

    private var pollingJob: ScheduledJob? = nil
    private var workspace: Workspace? = nil

    init(
        httpWorkspaceFetcher: HttpWorkspaceFetcher,
        pollingScheduler: Scheduler,
        pollingInterval: TimeInterval
    ) {
        self.httpWorkspaceFetcher = httpWorkspaceFetcher
        self.pollingScheduler = pollingScheduler
        self.pollingInterval = pollingInterval
    }

    func fetch() -> Workspace? {
        workspace
    }

    func initialize(completion: @escaping () -> ()) {
        httpWorkspaceFetcher.fetchIfModified { [weak self] workspace, error in
            self?.handle(workspace: workspace, error: error)
            completion()
        }
    }

    private func poll() {
        httpWorkspaceFetcher.fetchIfModified { [weak self] workspace, error in
            self?.handle(workspace: workspace, error: error)
        }
    }

    private func handle(workspace: Workspace?, error: Error?) {
        if let error = error {
            Log.error("Failed to fetch Workspace: \(error)")
        }
        guard let workspace else {
            return
        }
        self.workspace = workspace
    }

    func start() {
        if pollingInterval == HackleConfig.NO_POLLING {
            return
        }
        lock.write { [weak self] in
            if self?.pollingJob != nil {
                return
            }
            self?.pollingJob = self?.pollingScheduler.schedulePeriodically(
                delay: pollingInterval,
                period: pollingInterval,
                task: poll
            )
            Log.info("PollingWorkspaceFetcher started polling. Poll every \(pollingInterval)s")
        }
    }

    func stop() {
        if pollingInterval == HackleConfig.NO_POLLING {
            return
        }
        lock.write { [weak self] in
            self?.pollingJob?.cancel()
            self?.pollingJob = nil
            Log.info("PollingWorkspaceFetcher stopped polling.")
        }
    }

    func onChanged(state: AppState, timestamp: Date) {
        switch state {
        case .foreground:
            start()
        case .background:
            stop()
        }
    }
}

//
// Created by yong on 2020/12/11.
//

import Foundation

protocol WorkspaceFetcher {
    func getWorkspaceOrNil() -> Workspace?
    func initialize(completion: @escaping () -> ())
}

class PollingWorkspaceFetcher: WorkspaceFetcher, AppNotificationListener {

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

    func getWorkspaceOrNil() -> Workspace? {
        workspace
    }

    func initialize(completion: @escaping () -> ()) {
        httpWorkspaceFetcher.fetch { [weak self] workspace in
            self?.workspace = workspace
            completion()
        }
    }

    private func poll() {
        httpWorkspaceFetcher.fetch { [weak self] workspace in
            self?.workspace = workspace
        }
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
                delay: .zero,
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

    func onNotified(notification: AppNotification, timestamp: Date) {
        switch notification {
        case .didBecomeActive:
            start()
        case .didEnterBackground:
            stop()
        }
    }
}

protocol HttpWorkspaceFetcher {
    func fetch(completion: @escaping (Workspace?) -> ())
}

class DefaultHttpWorkspaceFetcher: HttpWorkspaceFetcher {

    private let endpoint: URL
    private let httpClient: HttpClient

    init(sdkBaseUrl: URL, httpClient: HttpClient) {
        self.endpoint = sdkBaseUrl.appendingPathComponent("/api/v2/workspaces")
        self.httpClient = httpClient
    }

    func fetch(completion: @escaping (Workspace?) -> ()) {
        let request = HttpRequest.get(url: endpoint)
        let sample = TimerSample.start()
        httpClient.execute(request: request) { response in
            ApiCallMetrics.record(operation: "get.workspace", sample: sample, isSuccess: response.isSuccessful)
            let workspace = self.getWorkspaceOrNil(response: response)
            Log.debug("Hackle workspace fetched")
            completion(workspace)
        }
    }

    private func getWorkspaceOrNil(response: HttpResponse) -> Workspace? {

        if let error = response.error {
            Log.error("Failed to fetch Workspace: \(error.localizedDescription)")
            return nil
        }

        guard let urlResponse = response.urlResponse as? HTTPURLResponse else {
            Log.error("Failed to fetch Workspace: Response is empty")
            return nil
        }

        guard (200..<300).contains(urlResponse.statusCode) else {
            Log.error("Failed to fetch Workspace: Http status code: \(urlResponse.statusCode)")
            return nil
        }

        guard let responseBody = response.data else {
            Log.error("Failed to fetch Workspace. Response body is empty")
            return nil
        }

        guard let workspaceDto = try? JSONDecoder().decode(WorkspaceDto.self, from: responseBody) else {
            Log.error("Failed to fetch Workspace. Invalid format")
            return nil
        }

        return WorkspaceEntity.from(dto: workspaceDto)
    }

    private func record(sample: TimerSample, isSuccess: Bool) {
        let timer = Metrics.timer(name: "workspace.fetch", tags: ["success": String(isSuccess)])
        sample.stop(timer: timer)
    }
}

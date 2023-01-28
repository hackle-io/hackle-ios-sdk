//
// Created by yong on 2020/12/11.
//

import Foundation

protocol WorkspaceFetcher {
    func getWorkspaceOrNil() -> Workspace?
    func fetchFromServer(completion: @escaping () -> ())
}

class CachedWorkspaceFetcher: WorkspaceFetcher {

    private var workspace: Workspace?
    private var httpWorkspaceFetcher: HttpWorkspaceFetcher

    init(httpWorkspaceFetcher: HttpWorkspaceFetcher) {
        self.httpWorkspaceFetcher = httpWorkspaceFetcher
    }

    func getWorkspaceOrNil() -> Workspace? {
        workspace
    }

    func fetchFromServer(completion: @escaping () -> ()) {
        httpWorkspaceFetcher.fetch { workspace in
            if let workspace = workspace {
                Log.info("Hackle workspace fetched")
                self.workspace = workspace
            }
            completion()
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
            Log.error("Failed to fetch Workspace. Responde body is empty")
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

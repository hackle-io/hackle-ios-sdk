//
// Created by yong on 2020/12/15.
//

import Foundation

protocol UserEventDispatcher {
    func dispatch(events: [UserEvent])
}

class DefaultUserEventDispatcher: UserEventDispatcher {

    private let endpoint: URL
    private let httpClient: HttpClient
    private let queue: DispatchQueue

    init(eventBaseUrl: URL, httpClient: HttpClient) {
        self.endpoint = eventBaseUrl.appendingPathComponent("/api/v2/events")
        self.httpClient = httpClient
        self.queue = DispatchQueue(label: "io.hackle.DefaultUserEventDispatcher")
    }

    func dispatch(events: [UserEvent]) {
        queue.async {
            self.dispatchToServer(events: events)
        }
    }

    private func dispatchToServer(events: [UserEvent]) {

        let payload = createPayload(events: events)
        guard let requestBody = Json.serialize(payload) else {
            return
        }

        let request = HttpRequest.post(url: endpoint, body: requestBody)

        httpClient.execute(request: request) { response in
            self.checkResponse(response: response)
        }
    }

    private func createPayload(events: [UserEvent]) -> EventPayloadDto {

        var exposures = [ExposureEventDto]()
        var tracks = [TrackEventDto]()

        for event in events {
            switch event {
            case let exposure as UserEvents.Exposure:

                let dto = exposure.toDto()
                if Json.isValid(dto) {
                    exposures.append(dto)
                }
            case let track as UserEvents.Track:
                let dto = track.toDto()
                if Json.isValid(dto) {
                    tracks.append(dto)
                }
            default:
                continue
            }
        }

        return [
            "exposureEvents": exposures,
            "trackEvents": tracks
        ]
    }

    private func checkResponse(response: HttpResponse) {
        if let error = response.error {
            Log.error("Failed to dispatch events: \(error.localizedDescription)")
            return
        }

        guard let urlResponse = response.urlResponse as? HTTPURLResponse else {
            Log.error("Failed to dispatch events: Response is empty")
            return
        }

        guard (200..<300).contains(urlResponse.statusCode) else {
            Log.error("Failed to dispatch events: Http status code: \(urlResponse.statusCode)")
            return
        }
    }
}

typealias ExposureEventDto = [String: Any]
typealias TrackEventDto = [String: Any]
typealias EventPayloadDto = [String: Any]

extension UserEvents.Exposure {
    func toDto() -> ExposureEventDto {
        var dto = ExposureEventDto()

        dto["timestamp"] = timestamp.epochMillis

        dto["userId"] = user.identifiers[IdentifierType.id.rawValue]
        dto["identifiers"] = user.identifiers
        dto["userProperties"] = user.properties
        dto["hackleProperties"] = user.hackleProperties

        dto["experimentId"] = experiment.id
        dto["experimentKey"] = experiment.key
        dto["experimentType"] = experiment.type.rawValue
        dto["variationId"] = variationId
        dto["variationKey"] = variationKey
        dto["decisionReason"] = decisionReason

        return dto
    }
}

extension UserEvents.Track {
    func toDto() -> TrackEventDto {
        var dto = TrackEventDto()

        dto["timestamp"] = timestamp.epochMillis

        dto["userId"] = user.identifiers[IdentifierType.id.rawValue]
        dto["identifiers"] = user.identifiers
        dto["userProperties"] = user.properties
        dto["hackleProperties"] = user.hackleProperties

        dto["eventTypeId"] = eventType.id
        dto["eventTypeKey"] = eventType.key
        if let value = event.value {
            dto["value"] = value
        }
        if let properties = event.properties {
            dto["properties"] = properties
        }
        return dto
    }
}

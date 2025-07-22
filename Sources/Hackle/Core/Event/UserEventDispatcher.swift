//
// Created by yong on 2020/12/15.
//

import Foundation

protocol UserEventDispatcher {
    func dispatch(events: [EventEntity])
}

class DefaultUserEventDispatcher: UserEventDispatcher {
    private let endpoint: URL
    private let eventQueue: DispatchQueue
    private let eventRepository: EventRepository
    private let httpQueue: DispatchQueue
    private let httpClient: HttpClient
    private let eventBackoffController: UserEventBackoffController

    init(eventBaseUrl: URL, eventQueue: DispatchQueue, eventRepository: EventRepository, httpQueue: DispatchQueue, httpClient: HttpClient, eventBackoffController: UserEventBackoffController) {
        self.endpoint = eventBaseUrl.appendingPathComponent("/api/v2/events")
        self.eventQueue = eventQueue
        self.eventRepository = eventRepository
        self.httpQueue = httpQueue
        self.httpClient = httpClient
        self.eventBackoffController = eventBackoffController
    }

    func dispatch(events: [EventEntity]) {
        httpQueue.async {
            self.eventDispatchInternal(events: events)
        }
    }

    private func delete(events: [EventEntity]) {
        eventQueue.async {
            self.deleteEventInternal(events: events)
        }
    }

    private func updateEventStatusToPending(events: [EventEntity]) {
        eventQueue.async {
            self.updateEventToPendingInternal(events: events)
        }
    }

    private func eventDispatchInternal(events: [EventEntity]) {
        guard let requestBody = toBody(events: events) else {
            Log.error("Failed to dispatch events: invalid requestBody")
            delete(events: events)
            return
        }

        let request = HttpRequest.post(url: endpoint, body: requestBody)

        let sample = TimerSample.start()
        httpClient.execute(request: request) { response in
            ApiCallMetrics.record(operation: "post.events", sample: sample, response: response)
            self.handleResponse(events: events, response: response)
        }
    }

    private func handleResponse(events: [EventEntity], response: HttpResponse) {
        eventBackoffController.checkResponse(response.isSuccessful)
        
        if let error = response.error {
            Log.error("Failed to dispatch events: \(error.localizedDescription)")
            updateEventStatusToPending(events: events)
            return
        }

        guard let urlResponse = response.urlResponse as? HTTPURLResponse else {
            Log.error("Failed to dispatch events: Response is empty")
            delete(events: events)
            return
        }

        if (200..<300).contains(urlResponse.statusCode) {
            delete(events: events)
            return
        }

        if (400..<500).contains(urlResponse.statusCode) {
            delete(events: events)
            return
        }

        updateEventStatusToPending(events: events)
    }

    private func deleteEventInternal(events: [EventEntity]) {
        eventRepository.delete(events: events)
    }

    private func updateEventToPendingInternal(events: [EventEntity]) {
        eventRepository.update(events: events, status: .pending)
    }

    private func toBody(events: [EventEntity]) -> Data? {
        var exposures = [String]()
        var tracks = [String]()
        var remoteConfigs = [String]()

        for event in events {
            switch event.type {
            case .exposure:
                exposures.append(event.body)
            case .track:
                tracks.append(event.body)
            case .remoteConfig:
                remoteConfigs.append(event.body)
            }
        }
        let exposurePayload = exposures.joined(separator: ",")
        let trackPayload = tracks.joined(separator: ",")
        let remoteConfigPayload = remoteConfigs.joined(separator: ",")

        let body = "{\"exposureEvents\":[\(exposurePayload)],\"trackEvents\":[\(trackPayload)],\"remoteConfigEvents\":[\(remoteConfigPayload)]}"
        return body.data(using: .utf8)
    }
}

typealias ExposureEventDto = [String: Any]
typealias TrackEventDto = [String: Any]
typealias RemoteConfigEventDto = [String: Any]
typealias EventPayloadDto = [String: Any]

extension UserEvents.Exposure {
    func toDto() -> ExposureEventDto {
        var dto = ExposureEventDto()

        dto["insertId"] = insertId
        dto["timestamp"] = timestamp.epochMillis

        dto["userId"] = user.identifiers[IdentifierType.id.rawValue]
        dto["identifiers"] = user.identifiers
        dto["userProperties"] = user.properties
        dto["hackleProperties"] = user.hackleProperties

        dto["experimentId"] = experiment.id
        dto["experimentKey"] = experiment.key
        dto["experimentType"] = experiment.type.rawValue
        dto["experimentVersion"] = experiment.version
        dto["variationId"] = variationId
        dto["variationKey"] = variationKey
        dto["decisionReason"] = decisionReason
        dto["properties"] = properties

        return dto
    }
}

extension UserEvents.Track {
    func toDto() -> TrackEventDto {
        var dto = TrackEventDto()

        dto["insertId"] = insertId
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

extension UserEvents.RemoteConfig {
    func toDto() -> RemoteConfigEventDto {
        var dto = RemoteConfigEventDto()

        dto["insertId"] = insertId
        dto["timestamp"] = timestamp.epochMillis

        dto["userId"] = user.identifiers[IdentifierType.id.rawValue]
        dto["identifiers"] = user.identifiers
        dto["userProperties"] = user.properties
        dto["hackleProperties"] = user.hackleProperties

        dto["parameterId"] = parameter.id
        dto["parameterKey"] = parameter.key
        dto["parameterType"] = parameter.type.rawValue
        dto["valueId"] = valueId
        dto["decisionReason"] = decisionReason
        dto["properties"] = properties

        return dto
    }
}

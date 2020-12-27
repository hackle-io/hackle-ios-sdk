//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Workspace {
    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment?

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType?
}

class WorkspaceEntity: Workspace {

    private let experiments: [Experiment.Key: Experiment]
    private let eventTypes: [EventType.Key: EventType]

    init(experiments: [Experiment.Key: Experiment], eventTypes: [EventType.Key: EventType]) {
        self.experiments = experiments
        self.eventTypes = eventTypes
    }

    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment? {
        experiments[experimentKey]
    }

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType? {
        eventTypes[eventTypeKey]
    }

    static func from(dto: WorkspaceDto) -> Workspace {

        let buckets = dto.buckets.associate { it in
            (it.id, it.toBucket())
        }

        let runningExperiments: [Experiment.Key: Experiment] = dto.experiments.associate { it in
            (it.key, it.toRunning(bucket: buckets[it.bucketId]!))
        }

        let completedExperiments: [Experiment.Key: Experiment] = dto.completedExperiments.associate { it in
            (it.experimentKey, it.toCompleted())
        }

        let eventTypes: [EventType.Key: EventType] = dto.events.associate { it in
            (it.key, it.toEventType())
        }
        return WorkspaceEntity(
            experiments: runningExperiments.merging(completedExperiments) {
                $1
            },
            eventTypes: eventTypes
        )
    }
}

class WorkspaceDto: Codable {
    var experiments: [ExperimentDto]
    var completedExperiments: [CompletedExperimentDto]
    var buckets: [BucketDto]
    var events: [EventTypeDto]
}

class ExperimentDto: Codable {
    var id: Int64
    var key: Int64
    var status: String
    var bucketId: Int64
    var variations: [VariationDto]
    var execution: ExecutionDto
}

class VariationDto: Codable {
    var id: Int64
    var key: String
    var status: String
}

class CompletedExperimentDto: Codable {
    var experimentId: Int64
    var experimentKey: Int64
    var winnerVariationId: Int64
    var winnerVariationKey: String
}

class ExecutionDto: Codable {
    var status: String
    var userOverrides: [UserOverrideDto]
}

class UserOverrideDto: Codable {
    var userId: String
    var variationId: Int64
}

class BucketDto: Codable {
    var id: Int64
    var seed: Int32
    var slotSize: Int32
    var slots: [SlotDto]
}

class SlotDto: Codable {
    var startInclusive: Int
    var endExclusive: Int
    var variationId: Int64
}

class EventTypeDto: Codable {
    var id: Int64
    var key: String
}

extension SlotDto {
    func toSlot() -> Slot {
        SlotEntity(startInclusive: startInclusive, endExclusive: endExclusive, variationId: variationId)
    }
}

extension BucketDto {
    func toBucket() -> Bucket {
        BucketEntity(seed: seed, slotSize: slotSize, slots: slots.map {
            $0.toSlot()
        })
    }
}

extension VariationDto {
    func toVariation() -> Variation {
        VariationEntity(id: id, key: key, isDropped: status == "DROPPED")
    }
}

extension ExperimentDto {
    func toRunning(bucket: Bucket) -> Running {
        RunningExperimentEntity(
            id: id,
            key: key,
            bucket: bucket,
            variations: variations.associate { it in
                (it.id, it.toVariation())
            },
            userOverrides: execution.userOverrides.associate { it in
                (it.userId, it.variationId)
            })
    }
}

extension CompletedExperimentDto {
    func toCompleted() -> Completed {
        CompletedExperimentEntity(id: experimentId, key: experimentKey, winnerVariationKey: winnerVariationKey)
    }
}

extension EventTypeDto {
    func toEventType() -> EventType {
        EventTypeEntity(id: id, key: key)
    }
}

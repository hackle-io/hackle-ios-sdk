//
//  ContainerResolver.swift
//  Hackle
//
//  Created by yong on 2022/07/21.
//

import Foundation

protocol ContainerResolver {
    func isUserInContainerGroup(request: ExperimentRequest, container: Container) throws -> Bool
}

class DefaultContainerResolver: ContainerResolver {
    private let bucketer: Bucketer

    init(bucketer: Bucketer) {
        self.bucketer = bucketer
    }

    func isUserInContainerGroup(request: ExperimentRequest, container: Container) throws -> Bool {
        guard let identifier = request.user.identifiers[request.experiment.identifierType] else {
            return false
        }

        guard let bucket = request.workspace.getBucketOrNil(bucketId: container.bucketId) else {
            throw HackleError.error("Bucket[\(container.bucketId)]")
        }

        guard let slot = bucketer.bucketing(bucket: bucket, identifier: identifier) else {
            return false
        }

        guard let containerGroup = container.getGroupOrNil(containerGroupId: slot.containerGroupId) else {
            throw HackleError.error("ContainerGroup[\(slot.variationId)]")
        }

        return containerGroup.experiments.contains(request.experiment.id)
    }
}

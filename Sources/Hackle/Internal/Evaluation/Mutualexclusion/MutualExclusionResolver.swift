import Foundation

protocol MutualExclusionResolver {
    func resolve(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Bool
}

class DefaultMutualExclusionResolver: MutualExclusionResolver {
    private let bucketer: Bucketer
    
    init(bucketer: Bucketer) {
        self.bucketer = bucketer
    }
    
    func resolve(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Bool {
        if experiment.contianerId == nil {
            return true
        }
        
        guard let container = workspace.getContainerOrNil(containerId: experiment.contianerId) else {
            throw HackleError.error("container group not exist. containerId[\(experiment.contianerId)]")
        }
        guard let bucket = workspace.getBucketOrNil(bucketId: container.bucketId) else {
            throw HackleError.error("container group bucket not exist. bucketId[\(container.bucketId)]")
        }
        guard let identifier = user.identifiers[experiment.identifierType] else {
            return false
        }

        guard let allocatedSlot = bucketer.bucketing(bucket: bucket, identifier: identifier) else {
            return false
        }
        guard let containerGoup = container.findGroup(containerGroupId: allocatedSlot.variationId) else {
            return false
        }
        return containerGoup?.experiments.contains(experiment.id)
    }
}

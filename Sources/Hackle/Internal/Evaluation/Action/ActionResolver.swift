import Foundation

protocol ActionResolver {
    func resolveOrNil(action: Action, workspace: Workspace, experiment: Experiment, user: User) throws -> Variation?
}

class DefaultActionResolver: ActionResolver {
    private let bucketer: Bucketer

    init(bucketer: Bucketer) {
        self.bucketer = bucketer
    }

    func resolveOrNil(action: Action, workspace: Workspace, experiment: Experiment, user: User) throws -> Variation? {
        switch action.type {
        case .variation:
            return try resolveVariation(action: action, experiment: experiment)
        case .bucket:
            return try resolveBucket(action: action, workspace: workspace, experiment: experiment, user: user)
        }
    }

    private func resolveVariation(action: Action, experiment: Experiment) throws -> Variation {
        guard let variationId = action.variationId else {
            throw HackleError.error("action variation[\(experiment.id)]")
        }

        guard let variation = experiment.getVariationOrNil(variationId: variationId) else {
            throw HackleError.error("variation[\(variationId)]")
        }

        return variation
    }

    private func resolveBucket(action: Action, workspace: Workspace, experiment: Experiment, user: User) throws -> Variation? {
        guard let bucketId = action.bucketId else {
            throw HackleError.error("action bucket[\(experiment.id)]")
        }
        guard let bucket = workspace.getBucketOrNil(bucketId: bucketId) else {
            throw HackleError.error("bucket[\(bucketId)]")
        }
        guard let allocatedSlot = bucketer.bucketing(bucket: bucket, user: user) else {
            return nil
        }
        return experiment.getVariationOrNil(variationId: allocatedSlot.variationId)
    }
}

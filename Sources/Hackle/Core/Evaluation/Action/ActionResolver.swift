import Foundation

protocol ActionResolver {
    func resolveOrNil(request: ExperimentRequest, action: Action) throws -> Variation?
}

class DefaultActionResolver: ActionResolver {
    private let bucketer: Bucketer

    init(bucketer: Bucketer) {
        self.bucketer = bucketer
    }

    func resolveOrNil(request: ExperimentRequest, action: Action) throws -> Variation? {
        switch action.type {
        case .variation:
            return try resolveVariation(request: request, action: action)
        case .bucket:
            return try resolveBucket(request: request, action: action)
        }
    }

    private func resolveVariation(request: ExperimentRequest, action: Action) throws -> Variation {
        guard let variationId = action.variationId else {
            throw HackleError.error("action variation[\(request.experiment.id)]")
        }

        guard let variation = request.experiment.getVariationOrNil(variationId: variationId) else {
            throw HackleError.error("variation[\(variationId)]")
        }

        return variation
    }

    private func resolveBucket(request: ExperimentRequest, action: Action) throws -> Variation? {
        guard let bucketId = action.bucketId else {
            throw HackleError.error("action bucket[\(request.experiment.id)]")
        }
        guard let bucket = request.workspace.getBucketOrNil(bucketId: bucketId) else {
            throw HackleError.error("bucket[\(bucketId)]")
        }
        guard let identifier = request.user.identifiers[request.experiment.identifierType] else {
            return nil
        }
        guard let allocatedSlot = bucketer.bucketing(bucket: bucket, identifier: identifier) else {
            return nil
        }
        return request.experiment.getVariationOrNil(variationId: allocatedSlot.variationId)
    }
}

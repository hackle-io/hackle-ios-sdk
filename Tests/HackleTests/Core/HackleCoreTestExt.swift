import Foundation
@testable import Hackle

extension DefaultHackleCore {

    /// Wires a full local-evaluation core for tests using the new EvaluateProcessor / LocalDecisionProcessor family.
    static func create(
        workspaceFetcher: ResourcesWorkspaceFetcher,
        eventProcessor: UserEventProcessor,
        manualOverrideStorage: ManualOverrideStorage,
        clock: Clock = SystemClock.shared
    ) -> DefaultHackleCore {
        let context = EvaluationContext()
        let impressionStorage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
        let hiddenStorage = DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository())
        context.register(impressionStorage)
        context.register(hiddenStorage)

        let evaluateProcessor = EvaluateProcessor.create(
            context: context,
            clock: clock,
            eventProcessor: eventProcessor,
            overrideStorage: manualOverrideStorage,
            impressionStorage: impressionStorage,
            hiddenStorage: hiddenStorage
        )

        let decisionProcessor = LocalDecisionProcessor(
            workspaceFetcher: ResourcesWorkspaceConfigFetcher(workspaceFetcher),
            evaluateProcessor: evaluateProcessor
        )

        return DefaultHackleCore(
            workspaceFetcher: workspaceFetcher,
            decisionProcessor: decisionProcessor,
            eventProcessor: eventProcessor,
            clock: clock
        )
    }
}

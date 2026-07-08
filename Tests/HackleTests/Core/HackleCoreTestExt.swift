import Foundation
@testable import Hackle

extension DefaultHackleCore {

    /// Wires a full local-evaluation core for tests using the new EvaluateProcessor / LocalDecisionProcessor family.
    static func create(
        workspaceManager: ResourcesWorkspaceManager,
        eventProcessor: UserEventProcessor,
        manualOverrideStorage: ManualOverrideStorage,
        clock: Clock = SystemClock.shared
    ) -> DefaultHackleCore {
        let context = HackleCoreContext()
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
            workspaceFetcher: ResourcesWorkspaceConfigFetcher(workspaceManager),
            evaluateProcessor: evaluateProcessor
        )

        return DefaultHackleCore(
            workspaceManager: workspaceManager,
            decisionProcessor: decisionProcessor,
            eventProcessor: eventProcessor,
            clock: clock
        )
    }
}

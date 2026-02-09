import Foundation


protocol TargetRule: Sendable {
    var target: Target { get }
    var action: Action { get }
}

final class TargetRuleEntity: TargetRule, Sendable {
    let target: Target
    let action: Action

    init(target: Target, action: Action) {
        self.target = target
        self.action = action
    }
}


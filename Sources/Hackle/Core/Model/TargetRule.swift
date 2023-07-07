import Foundation


protocol TargetRule {
    var target: Target { get }
    var action: Action { get }
}

class TargetRuleEntity: TargetRule {
    let target: Target
    let action: Action

    init(target: Target, action: Action) {
        self.target = target
        self.action = action
    }
}


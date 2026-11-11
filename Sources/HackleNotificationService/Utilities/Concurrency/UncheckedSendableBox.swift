import Foundation

/// non-Sendable 값을 `@Sendable` 클로저 경계 너머로 손으로 나른다.
/// 값이 정확히 1회 넘겨지고 동시 접근이 없는 경우에만 안전하다.
final class UncheckedSendableBox<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}

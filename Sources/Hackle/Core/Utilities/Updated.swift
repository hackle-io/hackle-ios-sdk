import Foundation

class Updated<T> {

    let previous: T
    let current: T

    init(previous: T, current: T) {
        self.previous = previous
        self.current = current
    }
}

extension Updated {
    func map<R>(_ transform: (T) -> R) -> Updated<R> {
        Updated<R>(previous: transform(previous), current: transform(current))
    }
}

//
// Created by yong on 2020/12/20.
//

import Foundation

class ReadWriteLock {

    private let queue: DispatchQueue

    init(label: String) {
        self.queue = DispatchQueue(label: label, attributes: .concurrent)
    }

    func read(block: () -> ()) {
        queue.sync(execute: block)
    }

    func read<T>(block: () -> T) -> T {
        queue.sync(execute: block)
    }

    func write(block: () -> ()) {
        queue.sync(flags: .barrier, execute: block)
    }

    func write<T>(block: () -> T) -> T {
        queue.sync(flags: .barrier, execute: block)
    }
}

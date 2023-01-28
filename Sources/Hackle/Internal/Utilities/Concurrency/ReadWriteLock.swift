//
// Created by yong on 2020/12/20.
//

import Foundation

class ReadWriteLock {

    private let queue: DispatchQueue

    init(label: String) {
        self.queue = DispatchQueue(label: label, attributes: .concurrent)
    }

    func read(block: () throws -> ()) rethrows {
        try queue.sync(execute: block)
    }

    func read<T>(block: () throws -> T) rethrows -> T {
        try queue.sync(execute: block)
    }

    func write(block: () throws -> ()) rethrows {
        try queue.sync(flags: .barrier, execute: block)
    }

    func write<T>(block: () throws -> T) rethrows -> T {
        try queue.sync(flags: .barrier, execute: block)
    }
}

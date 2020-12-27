//
// Created by yong on 2020/12/20.
//

import Foundation

class ConcurrentArray<T> {

    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.ConcurrentArray")
    private var array = [T]()

    var isEmpty: Bool {
        lock.read {
            array.isEmpty
        }
    }

    var size: Int {
        lock.read {
            array.count
        }
    }

    func add(_ element: T) {
        lock.write {
            array.append(element)
        }
    }

    func take() -> T? {
        var element: T? = nil
        lock.write {
            if !array.isEmpty {
                element = array.removeFirst()
            }
        }
        return element
    }

    func takeAll() -> [T] {
        var elements: [T]!
        lock.write {
            elements = array
            array.removeAll()
        }
        return elements
    }
}

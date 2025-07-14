//
//  AtomicNumber.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/14/25.
//

protocol AtomicNumber {
    associatedtype T: Numeric
    
    func get() -> T
    func set(_ value: T)
    func setAndGet(_ value: T) -> T
    func addAndGet(_ delta: T) -> T
    func incrementAndGet() -> T
}

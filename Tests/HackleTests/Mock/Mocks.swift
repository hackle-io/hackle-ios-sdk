//
// Created by yong on 2020/12/11.
//

import Nimble
import Quick
import Mockery


class StubScope<T, R> {
    private var mock: Mockable
    private var ref: MockReference<T, R>

    init(mock: Mockable, ref: MockReference<T, R>) {
        self.mock = mock
        self.ref = ref
    }

    func answers(_ answer: @escaping (T) throws -> R) {
        mock.registerResult(for: ref, result: answer)
    }

    func returns(_ returnValue: R) {
        answers { _ in
            returnValue
        }
    }
}

class ThrowStubScope<T, R> {
    private var mock: Mockable
    private var ref: MockReference<T, Result<R, Error>>

    init(mock: Mockable, ref: MockReference<T, Result<R, Error>>) {
        self.mock = mock
        self.ref = ref
    }

    func answers(_ answer: @escaping (T) throws -> R) {
        mock.registerResult(for: ref, result: resultF(answer))
    }

    func returns(_ returnValue: R) {
        answers { _ in
            returnValue
        }
    }

    func willThrow(_ error: Error) {
        answers { _ in
            throw error
        }
    }
}


func every<T, R>(_ mockFunction: MockFunction<T, R>) -> StubScope<T, R> {
    StubScope(mock: mockFunction.mock, ref: mockFunction.mockReference)
}

func every<T, R>(_ mockFunction: MockFunction<T, Result<R, Error>>) -> ThrowStubScope<T, R> {
    ThrowStubScope(mock: mockFunction.mock, ref: mockFunction.mockReference)
}

func verify<T, R>(exactly: Int? = nil, _ mockFunction: () -> MockFunction<T, R>) {
    let mockFunc = mockFunction()

    let invocations = mockFunc.mock.invokations(of: mockFunc.mockReference)

    if let exactly = exactly {
        expect(invocations.count).to(equal(exactly))
    } else {
        expect(invocations.count > 0).to(equal(true))
    }

}

struct MockFunction<T, R> {

    let mock: Mockable
    let mockReference: MockReference<T, R>

    init(_ mock: Mockable, _ function: @escaping (T) throws -> R) {
        self.mock = mock
        self.mockReference = MockReference(function)
    }

    func firstInvokation() -> MockInvokation<T, R> {
        invokations().first!
    }

    func lastInvokation() -> MockInvokation<T, R> {
        invokations().last!
    }

    func invokations() -> [MockInvokation<T, R>] {
        mock.invokations(of: mockReference)
    }

    func wasCalled() -> Bool {
        invokations().count > 0
    }

    func wasCalled(exactly: Int) -> Bool {
        invokations().count == exactly
    }

    func wasNotCalled() -> Bool {
        !wasCalled()
    }
}

extension MockFunction {
    static func throwable(_ mock: Mockable, _ function: @escaping (T) throws -> R) -> MockFunction<T, Result<R, Error>> {
        MockFunction<T, Result<R, Error>>(mock, resultF(function))
    }
}


extension Mockable {

    func call<T, R>(
        _ function: MockFunction<T, R>,
        args: T,
        file: StaticString = #file,
        line: UInt = #line,
        functionCall: StaticString = #function
    ) -> R {
        invoke(function.mockReference, args: args, fallback: fallback(file: file, line: line, functionCall: functionCall))
    }

    func call<T, R>(
        _ function: MockFunction<T, Result<R, Error>>,
        args: T,
        file: StaticString = #file,
        line: UInt = #line,
        functionCall: StaticString = #function
    ) throws -> R {
        try invoke(function.mockReference, args: args, fallback: fallback(file: file, line: line, functionCall: functionCall)).get()
    }

    private func fallback<R>(
        file: StaticString = #file,
        line: UInt = #line,
        functionCall: StaticString = #function
    ) -> R {
        if R.self == Void.self {
            let void = unsafeBitCast((), to: R.self)
            return void
        }
        let message = "You must register a result for '\(functionCall)' with `registerResult(for:)` before calling this function."
        preconditionFailure(message, file: file, line: line)
    }

    func call<T, R>(_ function: MockFunction<T, R?>, args: T) -> R? {
        invoke(function.mockReference, args: args)
    }
}

private func resultF<T, R>(_ function: @escaping (T) throws -> R) -> (T) -> Result<R, Error> {
    { t in
        do {
            return .success(try function(t))
        } catch let error {
            return .failure(error)
        }

    }
}

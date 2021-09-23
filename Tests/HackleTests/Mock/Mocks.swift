//
// Created by yong on 2020/12/11.
//

import Nimble
import Quick
import Mockery

class StubScope<Arguments, Result> {
    private var mock: Mockable
    private var ref: MockReference<Arguments, Result>

    init(mock: Mockable, ref: MockReference<Arguments, Result>) {
        self.mock = mock
        self.ref = ref
    }

    func answers(_ answer: @escaping (Arguments) throws -> Result) {
        mock.registerResult(for: ref, result: answer)
    }

    func returns(_ returnValue: Result) {
        answers { _ in
            returnValue
        }
    }
}

func every<Arguments, Result>(_ mockFunction: MockFunction<Arguments, Result>) -> StubScope<Arguments, Result> {
    StubScope(mock: mockFunction.mock, ref: mockFunction.mockReference)
}

func verify<Arguments, Result>(exactly: Int? = nil, _ mockFunction: () -> MockFunction<Arguments, Result>) {
    let mockFunc = mockFunction()

    let invocations = mockFunc.mock.invokations(of: mockFunc.mockReference)

    if let exactly = exactly {
        expect(invocations.count).to(equal(exactly))
    } else {
        expect(invocations.count > 0).to(equal(true))
    }

}

struct MockFunction<Arguments, Result> {

    let mock: Mockable
    let mockReference: MockReference<Arguments, Result>

    init(_ mock: Mockable, _ function: @escaping (Arguments) throws -> Result) {
        self.mock = mock
        self.mockReference = MockReference(function)
    }

    func invokations() -> [MockInvokation<Arguments, Result>] {
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


extension Mockable {

    func call<Arguments, Result>(
        _ function: MockFunction<Arguments, Result>,
        args: Arguments,
        file: StaticString = #file,
        line: UInt = #line,
        functionCall: StaticString = #function
    ) -> Result {
        return invoke(function.mockReference, args: args, file: file, line: line, functionCall: functionCall)
    }

    func call<Arguments, Result>(
        _ function: MockFunction<Arguments, Result?>,
        args: Arguments
    ) -> Result? {
        return invoke(function.mockReference, args: args)
    }
}
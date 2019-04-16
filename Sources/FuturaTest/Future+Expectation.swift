/* Copyright 2019 Miquido
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */

import Futura
import XCTest

public extension Future {

    /// Asserts Future value if appeared. Fails if there was no value or timed out.
    /// Assertion is performed by TestExpectation.
    /// Note that waiting for expectation will block current thread.
    /// Waiting will be performed automatically if returned value is ignored.
    ///
    /// - Parameter validation: Value validation function, assertion will fail if returns false
    /// - Parameter timeout: Wait timeout in seconds, default is 3
    /// - Returns: Test expectation of this assertion, it will wait immediately if not used
    @discardableResult
    func expectValue(_ validation: @escaping (Value) -> Bool = { _ in true },
                     timeout: UInt8 = 3,
                     message: @escaping @autoclosure () -> String = String(),
                     file: StaticString = #file,
                     line: UInt = #line) -> TestExpectation
    {
        let expectation: TestExpectation = .init(timeout: timeout, file: file, line: line)
        let valueAppeared: AtomicFlag.Pointer = AtomicFlag.make()
        
        self.value { [weak expectation] (value) in
            defer { AtomicFlag.readAndSet(valueAppeared) }
            guard let expectation = expectation else { return }
            guard !expectation.timedOut else { return }
            let result = validation(value)
            guard !result else {
                return
            }
            let message = message()
            XCTFail(message.isEmpty ? "Invalid value" : message, file: file, line: line)
        }
        self.always { [weak expectation] in
            guard let expectation = expectation else { return }
            defer { expectation.fulfill() }
            guard !AtomicFlag.readAndSet(valueAppeared) else { return }
            guard !expectation.timedOut else { return }
            XCTFail("Future completed without value", file: file, line: line)
        }

        return expectation
    }
    
    /// Asserts Future error if appeared. Fails if there was no error or timed out.
    /// Assertion is performed by TestExpectation.
    /// Note that waiting for expectation will block current thread.
    /// Waiting will be performed automatically if returned value is ignored.
    ///
    /// - Parameter validation: Error validation function, assertion will fail if returns false
    /// - Parameter timeout: Wait timeout in seconds, default is 3
    /// - Returns: Test expectation of this assertion, it will wait immediately if not used
    @discardableResult
    func expectError(_ validation: @escaping (Error) -> Bool = { _ in true },
                     timeout: UInt8 = 3,
                     message: @escaping @autoclosure () -> String = String(),
                     file: StaticString = #file,
                     line: UInt = #line) -> TestExpectation
    {
        let expectation: TestExpectation = .init(timeout: timeout, file: file, line: line)
        let errorAppeared: AtomicFlag.Pointer = AtomicFlag.make()
        
        self.error {  [weak expectation] (error) in
            defer { AtomicFlag.readAndSet(errorAppeared) }
            guard let expectation = expectation else { return }
            guard !expectation.timedOut else { return }
            let result = validation(error)
            guard !result else {
                return
            }
            let message = message()
            XCTFail(message.isEmpty ? "Invalid error" : message, file: file, line: line)
            
        }
        self.always { [weak expectation] in
            guard let expectation = expectation else { return }
            defer { expectation.fulfill() }
            guard !AtomicFlag.readAndSet(errorAppeared) else { return }
            guard !expectation.timedOut else { return }
            XCTFail("Future completed without error", file: file, line: line)
        }
        
        return expectation
    }
    
    /// Asserts if Future was cancelled. Fails if not cancelled or timed out.
    /// Assertion is performed by TestExpectation.
    /// Note that waiting for expectation will block current thread.
    /// Waiting will be performed automatically if returned value is ignored.
    ///
    /// - Parameter timeout: Wait timeout in seconds, default is 3
    /// - Returns: Test expectation of this assertion, it will wait immediately if not used
    @discardableResult
    func expectCancelled(timeout: UInt8 = 3,
                         message: @escaping @autoclosure () -> String = String(),
                         file: StaticString = #file,
                         line: UInt = #line) -> TestExpectation
    {
        let expectation: TestExpectation = .init(timeout: timeout, file: file, line: line)
        
        self.resulted { [weak expectation] in
            guard let expectation = expectation else { return }
            guard !expectation.timedOut else { return }
            XCTFail("Future completed with result", file: file, line: line)
        }
        self.always { [weak expectation] in
            guard let expectation = expectation else { return }
            expectation.fulfill()
        }
        
        return expectation
    }
}


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

public extension Signal {
    
    /// Asserts Signal values if appeared. Fails if there was too few values or timed out.
    /// Timeout assertion is performed by TestExpectation when executing `waitForExpectation()`.
    /// Note that waiting for expectation will block current thread.
    /// Waiting have to be done manually by calling `waitForExpectation()` on returned Expectation.
    ///
    /// - Parameter count: Number of values it will wait for, default is 1
    /// - Parameter validation: Value validation function, assertion will fail if returns false
    /// - Parameter timeout: Wait timeout in seconds, default is 3
    /// - Parameter message: Custom failure message
    /// - Returns: Test expectation of this assertion
    func expectValues(count: UInt = 1,
                      _ validation: @escaping ([Value]) -> Bool = { _ in true },
                      timeout: UInt8 = 3,
                      message: @escaping @autoclosure () -> String = String(),
                      file: StaticString = #file,
                      line: UInt = #line) -> TestExpectation
    {
        let expectation: TestExpectation = .init(timeout: timeout, file: file, line: line)
        
        var valuesList: Array<Value> = .init()
        let valuesMutex: Mutex.Pointer = Mutex.make(recursive: true)
        
        self.values { [weak expectation] (value) in
            guard let expectation = expectation else { return }
            Mutex.lock(valuesMutex)
            defer { Mutex.unlock(valuesMutex) }
            
            if valuesList.count < count {
                valuesList.append(value)
            } else { /* nothing */ }
            guard valuesList.count == count else { return }
            guard !expectation.timedOut else { return }
            defer { expectation.fulfill() }
            let result = validation(valuesList)
            guard !result else { return }
            let message = message()
            XCTFail(message.isEmpty ? "Invalid values" : message, file: file, line: line)
        }
        self.finished {
            Mutex.destroy(valuesMutex)
        }
        
        return expectation
    }
    
    /// Asserts Signal errors if appeared. Fails if there was too few errors or timed out.
    /// Timeout assertion is performed by TestExpectation when executing `waitForExpectation()`.
    /// Note that waiting for expectation will block current thread.
    /// Waiting have to be done manually by calling `waitForExpectation()` on returned Expectation.
    ///
    /// - Parameter count: Number of errors it will wait for, default is 1
    /// - Parameter validation: Error validation function, assertion will fail if returns false
    /// - Parameter timeout: Wait timeout in seconds, default is 3
    /// - Parameter message: Custom failure message
    /// - Returns: Test expectation of this assertion
    func expectErrors(count: UInt = 1,
                      _ validation: @escaping ([Error]) -> Bool = { _ in true },
                      timeout: UInt8 = 3,
                      message: @escaping @autoclosure () -> String = String(),
                      file: StaticString = #file,
                      line: UInt = #line) -> TestExpectation
    {
        let expectation: TestExpectation = .init(timeout: timeout, file: file, line: line)
        
        var errorsList: Array<Error> = .init()
        let errorsMutex: Mutex.Pointer = Mutex.make(recursive: true)
        
        self.errors { [weak expectation] (error) in
            guard let expectation = expectation else { return }
            Mutex.lock(errorsMutex)
            defer { Mutex.unlock(errorsMutex) }
            if errorsList.count < count {
                errorsList.append(error)
            } else { /* nothing */ }
            guard errorsList.count == count else { return }
            guard !expectation.timedOut else { return }
            defer { expectation.fulfill() }
            let result = validation(errorsList)
            guard !result else { return }
            let message = message()
            XCTFail(message.isEmpty ? "Invalid errors" : message, file: file, line: line)
        }
        self.finished {
            Mutex.destroy(errorsMutex)
        }
        
        return expectation
    }
    
    /// Asserts Signal is terminated. Fails if it was finished without error or timed out.
    /// Timeout assertion is performed by TestExpectation when executing `waitForExpectation()`.
    /// Note that waiting for expectation will block current thread.
    /// Waiting have to be done manually by calling `waitForExpectation()` on returned Expectation.
    ///
    /// - Parameter validation: Error validation function, assertion will fail if returns false
    /// - Parameter timeout: Wait timeout in seconds, default is 3
    /// - Parameter message: Custom failure message
    /// - Returns: Test expectation of this assertion
    func expectTerminated(_ validation: @escaping (Error) -> Bool = { _ in true },
                      timeout: UInt8 = 3,
                      message: @escaping @autoclosure () -> String = String(),
                      file: StaticString = #file,
                      line: UInt = #line) -> TestExpectation
    {
        let expectation: TestExpectation = .init(timeout: timeout, file: file, line: line)
        
        self.terminated { [weak expectation] reason in
            guard let expectation = expectation else { return }
            defer { expectation.fulfill() }
            let result = validation(reason)
            guard !result else { return }
            let message = message()
            XCTFail(message.isEmpty ? "Invalid error" : message, file: file, line: line)
        }
        
        
        return expectation
    }
    
    /// Asserts Signal is ended. Fails if it was finished with error or timed out.
    /// Timeout assertion is performed by TestExpectation when executing `waitForExpectation()`.
    /// Note that waiting for expectation will block current thread.
    /// Waiting have to be done manually by calling `waitForExpectation()` on returned Expectation.
    ///
    /// - Parameter timeout: Wait timeout in seconds, default is 3
    /// - Parameter message: Custom failure message
    /// - Returns: Test expectation of this assertion
    func expectEnded(timeout: UInt8 = 3,
                     message: @escaping @autoclosure () -> String = String(),
                     file: StaticString = #file,
                     line: UInt = #line) -> TestExpectation
    {
        let expectation: TestExpectation = .init(timeout: timeout, file: file, line: line)
        
        self.ended { [weak expectation] in
            guard let expectation = expectation else { return }
            expectation.fulfill()
        }
        
        return expectation
    }
}

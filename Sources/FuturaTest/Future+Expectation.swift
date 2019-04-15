/* Copyright 2018 Miquido
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */

@testable import Futura
import XCTest

public extension Future {

    /// Asserts Future value if appeared. Fails if there was no value or timed out.
    /// Note that waiting for expeectation will block current thread.
    /// Waiting will be performed automatically if returned
    /// value is ignored.
    ///
    /// - Parameter validation: Value validation function, assertion will fail if returns false
    /// - Parameter timeout: Wait timeout in seconds
    /// - Returns: Test expectation of this assertion, it will wait immediately if not used
    @discardableResult
    func expectValue(_ validation: @escaping (Value) -> Bool = { _ in true },
                     timeout: UInt8 = 3,
                     message: @escaping @autoclosure () -> String = String(),
                     file: StaticString = #file,
                     line: UInt = #line) -> TestExpectation
    {
        let assertionMutex: Mutex.Pointer = Mutex.make(recursive: false)
        Mutex.lock(assertionMutex)
        let valueLock: RecursiveLock = .init()
        var valueAppeared: Bool = false
        
        self.value { (value) in
            valueLock.synchronized { valueAppeared = true }
            let result = validation(value)
            guard !result else {
                return
            }
            let message = message()
            XCTFail(message.isEmpty ? "Invalid value" : message, file: file, line: line)
        }
        self.always {
            defer { Mutex.unlock(assertionMutex) }
            guard valueLock.synchronized({ valueAppeared }) else {
                return XCTFail("Future completed without value", file: file, line: line)
            }
        }

        return .init(assertionMutex,
                     timeout: timeout,
                     file: file,
                     line: line)
    }
    
    /// Asserts Future error if appeared. Fails if there was no error or timed out.
    /// Note that calling this method will block current thread.
    ///
    /// - Parameter validation: Error validation function, assertion will fail if returns false
    /// - Parameter timeout: Wait timeout in seconds
    /// - Returns: Test expectation of this assertion, it will wait immediately if not used
    func expectError(_ validation: @escaping (Error) -> Bool = { _ in true },
                     timeout: UInt8 = 3,
                     message: @escaping @autoclosure () -> String = String(),
                     file: StaticString = #file,
                     line: UInt = #line) -> TestExpectation
    {
        let assertionMutex: Mutex.Pointer = Mutex.make(recursive: false)
        Mutex.lock(assertionMutex)

        let errorLock: RecursiveLock = .init()
        var errorAppeared: Bool = false
        
        self.error { (error) in
            errorLock.synchronized { errorAppeared = true }
            let result = validation(error)
            guard !result else {
                return
            }
            let message = message()
            XCTFail(message.isEmpty ? "Invalid error" : message, file: file, line: line)
            
        }
        self.always {
            defer { Mutex.unlock(assertionMutex) }
            guard errorLock.synchronized({ errorAppeared }) else {
                return XCTFail("Future completed without error", file: file, line: line)
            }
        }
        
        return .init(assertionMutex,
                     timeout: timeout,
                     file: file,
                     line: line)
    }
    
    /// Asserts if Future was cancelled. Fails if not cancelled or timed out.
    /// Note that calling this method will block current thread.
    ///
    /// - Parameter timeout: Wait timeout in seconds
    /// - Returns: Test expectation of this assertion, it will wait immediately if not used
    func expectCancelled(timeout: UInt8 = 3,
                         message: @escaping @autoclosure () -> String = String(),
                         file: StaticString = #file,
                         line: UInt = #line) -> TestExpectation
    {
        let assertionMutex: Mutex.Pointer = Mutex.make(recursive: false)
        Mutex.lock(assertionMutex)
        
        self.resulted {
            XCTFail("Future completed with result", file: file, line: line)
        }
        self.always {
            Mutex.unlock(assertionMutex)
        }
        
        return .init(assertionMutex,
                     timeout: timeout,
                     file: file,
                     line: line)
    }
}


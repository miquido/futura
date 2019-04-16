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

public extension XCTestCase {

    /// Simple wrapper for async test where you want
    /// to have your test body on non main queue
    /// or simplify waiting and timeouts
    /// of your asynchronous code.
    /// It will block main (current) queue until completed.
    ///
    /// - Parameter timeout: Wait timeout in seconds, default is 3
    /// - Parameter testBody: body pf test that will be executed
    func asyncTest(timeout: UInt8 = 3,
                   file: StaticString = #file,
                   line: UInt = #line,
                   testBody: @escaping (@escaping () -> Void) -> Void) {
        let testQueue: DispatchQueue = .init(label: "AsyncTestQueue")
        let expectation: TestExpectation = .init(timeout: timeout, file: file, line: line)
        
        testQueue.async {
            testBody { [weak expectation] in
                expectation?.fulfill()
            }
        }
        expectation.waitForExpectation()
    }
}

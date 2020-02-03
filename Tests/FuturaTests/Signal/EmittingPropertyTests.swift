/* Copyright 2020 Miquido

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
import FuturaTest
import XCTest

class EmittingPropertyTests: XCTestCase {
    
    final class TestClass<T> {
        @Emitting var testProperty: T
        
        init(testProperty: T) {
            self.testProperty = testProperty
        }
        
        var signal: Signal<T> { _testProperty.signal }
    }
    
    var workLog: StreamWorkLog = .init()

    override func setUp() {
        super.setUp()
        workLog = .init()
    }
    
    func testShouldHandleValue_WhenMutatingValue() {
        let testClass = TestClass<Int>(testProperty: 0)
        testClass.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        testClass.testProperty = 42
        testClass.testProperty = 17
        XCTAssertEqual(workLog, [.values(testDescription(of: 42)), .tokens, .values(testDescription(of: 17)), .tokens])
    }
    
    func testShouldHandleNothing_WhenNotMutatingValue() {
        let testClass = TestClass<Int>(testProperty: 0)
        testClass.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        XCTAssertEqual(workLog, [])
    }
    
    func testShouldHandleEnd_WhenDeallocating() {
        var testClass: TestClass? = TestClass<Int>(testProperty: 0)
        testClass?.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }
        testClass = nil
        XCTAssertEqual(workLog, [.ended, .finished])
    }
}


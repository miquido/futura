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

/// TestExpectation holds async expectation.
/// It allows to choose wheater to wait immediately
/// or postpone waiting to better moment i.e. when
/// test set up properly.
/// Waiting for expectation will be performed automatically
/// if TestExpectation becomes deallocated.
/// Waiting will not be performed if already done.
public final class TestExpectation {
    
    private let waitingMutex: Mutex.Pointer = Mutex.make(recursive: false)
    private let timeout: UInt8
    private let timeoutFlag: AtomicFlag.Pointer = AtomicFlag.make()
    private let file: StaticString
    private let line: UInt
    private var executed: AtomicFlag.Pointer = AtomicFlag.make()

    internal init(timeout: UInt8,
                  file: StaticString = #file,
                  line: UInt = #line)
    {
        self.timeout = timeout
        self.file = file
        self.line = line
        Mutex.lock(waitingMutex)
    }
    
    deinit {
        waitForExpectation()
        AtomicFlag.destroy(executed)
        AtomicFlag.destroy(timeoutFlag)
        Mutex.destroy(waitingMutex)
    }
    
    internal func fulfill() {
        Mutex.unlock(waitingMutex)
    }
    
    internal var timedOut: Bool {
        guard !AtomicFlag.readAndSet(timeoutFlag) else {
            return true
        }
        // clearing flag here might cause extreamly rare cases
        // where flag was set outside and cleared here
        // it have to be used in a way that after reading this value
        // it should not be read again
        return false
    }
    
    /// Waits for given expectation until done or times out.
    /// Waiting will not be performed if already done.
    /// Timeout time is defined by function producing this exceptation.
    /// Note that this operation is blocking current thread.
    public func waitForExpectation() {
        guard !AtomicFlag.readAndSet(executed) else { return }
        do {
            try Mutex.lock(waitingMutex, timeout: timeout)
        } catch {
            AtomicFlag.readAndSet(timeoutFlag)
            return XCTFail("Timed out", file: file, line: line)
        }
    }
}

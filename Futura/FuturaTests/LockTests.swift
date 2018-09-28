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

import XCTest
import Futura

class LockTests: XCTestCase {
    
    func testReleasingLockedLock() {
        Lock().lock()
    }
    
    func testLockLock() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var completed: Bool = false
            let lock = Lock()
            lock.lock()
            DispatchQueue.global().async {
                lock.lock()
                XCTAssert(completed, "Lock unlocked while should be locked")
                complete()
            }
            sleep(1)
            completed = true
            lock.unlock()
        }
    }
    
    func testLockLockAndUnlock() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            DispatchWorker.default.schedule {
                lock.unlock()
            }
            lock.lock()
            complete()
        }
    }
    
    func testLockTryLockSuccess() {
        let lock = Lock()
        if lock.tryLock() {
            // expected
        } else {
            XCTFail("Lock failed to lock")
        }
    }
    
    func testLockTryLockFail() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            
            DispatchQueue.global().async {
                if lock.tryLock() {
                    XCTFail("Lock not failed to lock")
                } else {
                    // expected
                }
                complete()
            }
        }
    }
    
    func testLockRecursive() {
        asyncTest(timeoutBody: {
                    XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            lock.lock()
            lock.lock()
            lock.unlock()
            lock.unlock()
            lock.unlock()
            complete()
        }
    }
    
    func testLockRecursiveWithSleeps() {
        asyncTest(iterationTimeout: 6,
            timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            sleep(1)
            lock.lock()
            sleep(1)
            lock.lock()
            sleep(1)
            lock.unlock()
            sleep(1)
            lock.unlock()
            sleep(1)
            lock.unlock()
            complete()
        }
    }
    
    func testLockSynchronizedRecursive() {
        asyncTest(iterationTimeout: 6,
                  timeoutBody: {
                    XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.synchronized {
                lock.synchronized {
                    lock.synchronized {
                        lock.synchronized {
                            lock.synchronized {
                                return Void()
                            }
                        }
                    }
                }
            }
            complete()
        }
    }
    
    func testLockSynchronizedRecursiveWithSleeps() {
        asyncTest(iterationTimeout: 6,
            timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.synchronized {
                sleep(1)
                lock.synchronized {
                    sleep(1)
                    lock.synchronized {
                        sleep(1)
                        lock.synchronized {
                            sleep(1)
                            lock.synchronized {
                                _ = sleep(1)
                            }
                        }
                    }
                }
            }
            complete()
        }
    }
    
    func testLockSynchronized() {
        asyncTest(iterationTimeout: 5, timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var testValue = 0
            let lock = Lock()
            DispatchWorker.default.schedule {
                sleep(1)
                lock.synchronized {
                    XCTAssert(testValue == 1, "Test value not changed")
                    testValue = -1
                }
            }
            lock.synchronized {
                testValue = 1
                sleep(2)
                XCTAssert(testValue == 1, "Test value changed without synchronization")
            }
            sleep(1)
            lock.synchronized {
                XCTAssert(testValue == -1, "Test value not changed before completing")
            }
            complete()
        }
    }
    
    func testThrowingLockSynchronized() {
        let lock = Lock()
        do {
            try lock.synchronized {
                throw TestError()
            }
            XCTFail("Lock not threw")
        } catch {
            // expected
        }
    }
    
    func testLockAndUnlockPerformance() {
        measure {
            let lock = Lock()
            var total = 0
            for _ in 0..<performanceTestIterations {
                lock.lock()
                total += 1
                lock.unlock()
            }
            XCTAssert(total == performanceTestIterations)
        }
    }
    
}

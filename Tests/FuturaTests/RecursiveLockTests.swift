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

import Futura
import FuturaTest
import XCTest

class RecursiveLockTests: XCTestCase {
    func testShouldNotCrash_When_ReleasingLocked() {
        RecursiveLock().lock()
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldLockAndUnlock_WhenCalledOnDistinctThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            let lock: RecursiveLock = .init()
            var completed: Bool = false

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

    func testShouldLockAndUnlock_WhenCalledOnSameThread() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            let lock: RecursiveLock = .init()

            lock.lock()
            lock.lock()
            lock.lock()
            lock.unlock()
            lock.unlock()
            lock.unlock()

            complete()
        }
    }

    func testShouldSucceedTryLock_WhenUnlocked() {
        let lock: RecursiveLock = .init()

        guard lock.tryLock() else {
            return XCTFail("Lock failed to lock")
        }
    }

    func testShouldSucceedTryLock_WhenLockedOnSameThread() {
        let lock: RecursiveLock = .init()
        lock.lock()

        guard lock.tryLock() else {
            return XCTFail("Lock failed to lock")
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldFailTryLock_WhenLockedOnOtherThread() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            let lock: RecursiveLock = .init()
            lock.lock()

            DispatchQueue.global().async {
                defer { complete() }
                guard !lock.tryLock() else {
                    return XCTFail("Lock not failed to lock")
                }
            }
            sleep(1) // ensure that will not exit too early deallocating lock
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldSynchronizeBlock_WhenCalledOnDistinctThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            let lock: RecursiveLock = .init()
            var testValue = 0

            DispatchQueue.global().async {
                lock.synchronized {
                    sleep(2) // ensure that claims lock longer
                    XCTAssert(testValue == 0, "Test value changed without synchronization")
                    testValue += 1
                }
            }
            sleep(1) // ensure that DispatchWorker performs its task before
            lock.synchronized {
                XCTAssert(testValue == 1, "Test value changed without synchronization")
            }

            complete()
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldNotCauseDeadlock_WhenSynchronizedCalledRecursively() {
        asyncTest(iterationTimeout: 6,
                  timeoutBody: {
                      XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            let lock: RecursiveLock = .init()
            var completed: Bool = false

            lock.synchronized {
                lock.synchronized {
                    lock.synchronized {
                        lock.synchronized {
                            lock.synchronized {
                                completed = true
                            }
                        }
                    }
                }
            }

            XCTAssert(completed, "Synchronized blocks not performed")
            complete()
        }
    }

    func testShouldThrowInSynchronizedWithoutChangingError() {
        let lock: RecursiveLock = .init()
        let expectedResult = TestError()

        do {
            try lock.synchronized { throw expectedResult }
            XCTFail("Lock not threw")
        } catch {
            XCTAssert(error is TestError, "Catched error does not match expected. Expected: \(expectedResult) Received: \(error)")
        }
    }
}

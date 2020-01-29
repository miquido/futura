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

class LockTests: XCTestCase {

    func testShouldNotCrash_When_ReleasingLocked() {
        Lock().lock()
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldLockAndUnlock_WhenCalledOnDistinctThreads() {
        asyncTest { complete in
            let lock: Lock = .init()
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

    func testShouldSucceedTryLock_WhenUnlocked() {
        let lock: Lock = .init()

        guard lock.tryLock() else {
            return XCTFail("Lock failed to lock")
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldFailTryLock_WhenLockedOnOtherThread() {
        asyncTest { complete in
            let lock: Lock = .init()
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
    
    func testShouldTimeout() {
        let lock = Lock()
        lock.lock()
        do {
            try lock.lock(timeout: 1)
            XCTFail("Lock not failed to lock")
        } catch {
            // expected
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldSynchronizeBlock_WhenCalledOnDistinctThreads() {
        asyncTest { complete in
            let lock: Lock = .init()
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

    func testShouldThrowInSynchronizedWithoutChangingError() {
        let lock: Lock = .init()
        let expectedResult = TestError()

        do {
            try lock.synchronized { throw expectedResult }
            XCTFail("Lock not threw")
        } catch {
            XCTAssert(error is TestError, "Catched error does not match expected. Expected: \(expectedResult) Received: \(error)")
        }
    }
}

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
import XCTest

class FuturaWorkerTests: XCTestCase {
    var worker: FuturaWorker!
    var lock: RecursiveLock = .init()

    override func setUp() {
        super.setUp()
        worker = FuturaWorker()
        lock = .init()
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldDealocateIdle() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            weak var weakWorker: FuturaWorker? = self.worker

            XCTAssertNotNil(weakWorker)
            self.worker = nil
            XCTAssertNil(weakWorker)

            sleep(1)
            complete()
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldDealocateWithTasks() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            weak var weakWorker: FuturaWorker? = self.worker

            XCTAssertNotNil(weakWorker)

            weakWorker?.schedule {
                sleep(2)
            }
            self.worker = nil

            XCTAssertNil(weakWorker)
            complete()
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldPerformTask_AfterWorkScheduled() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            self.worker.schedule { () -> Void in
                complete()
            }
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldPerformTasks_AfterWorkScheduledRecursively() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            self.worker.schedule { () -> Void in
                self.worker.schedule { () -> Void in
                    self.worker.schedule { () -> Void in
                        complete()
                    }
                }
            }
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldPerformTask_AfterWorkScheduledWithIdleDelay() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            var called = false

            sleep(1)
            self.worker.schedule { () -> Void in
                self.lock.synchronized { called = true }
            }
            sleep(1)
            XCTAssertTrue(self.lock.synchronized { called })
            complete()
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldPerformTasks_AfterWorkScheduledWithIdlePeriod() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            var called_1 = false
            var called_2 = false

            self.worker.schedule { () -> Void in
                self.lock.synchronized { called_1 = true }
            }
            sleep(1)
            self.worker.schedule { () -> Void in
                self.lock.synchronized { called_2 = true }
            }

            sleep(1)
            XCTAssertTrue(self.lock.synchronized { called_1 })
            XCTAssertTrue(self.lock.synchronized { called_2 })
            complete()
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldPerformTasks_AfterLotOfWorkScheduled() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            var counter = 0

            for _ in 0 ..< 100 {
                self.worker.schedule { () -> Void in
                    counter += 1
                    guard counter == 100 else { return }
                    complete()
                }
            }
        }
    }

    // make sure that tests run with thread sanitizer enabled
    func testShouldPerformTasks_AfterDealocateWithTasks() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            weak var weakWorker: FuturaWorker? = self.worker

            XCTAssertNotNil(weakWorker)

            weakWorker?.schedule {
                sleep(1)
                complete()
            }

            self.worker = nil

            XCTAssertNil(weakWorker)
        }
    }
}

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

class FutureZipTests: XCTestCase {
    
    var worker: TestWorker = .init()
    var workLog: FutureWorkLog = .init()
    var promise_1: Promise<Int> = .init()
    var promise_2: Promise<Int> = .init()
    
    override func setUp() {
        super.setUp()
        worker = .init()
        workLog = .init()
        promise_1 = .init(executionContext: .explicit(worker))
        promise_2 = .init(executionContext: .explicit(worker))
    }
    
    // MARK: -
    // MARK: completing
    
    func testShouldHandleValue_WhenCompletingWithValueOnBoth() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.fulfill(with: 0)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        
        promise_2.fulfill(with: 0)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        
        XCTAssertEqual(workLog, [.then(testDescription(of: (0, 0))), .resulted, .always])
    }
    
    func testShouldHandleValue_WhenCompletingWithValueOnBothReversed() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.fulfill(with: 0)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        
        promise_1.fulfill(with: 0)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        
        XCTAssertEqual(workLog, [.then(testDescription(of: (0, 0))), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithErrorOnFirst_WhileSecondWaiting() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.break(with: testError)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
        
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithErrorOnSecond_WhileFirstWaiting() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.break(with: testError)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
        
        promise_1.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithErrorOnFirst_WhileSecondSucceeded() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise_1.break(with: testError)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithErrorOnSecond_WhileFirstSucceeded() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise_2.break(with: testError)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancelOnFirst_WhileSecondWaiting() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.cancel()
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
        
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancelOnSecond_WhileFirstWaiting() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.cancel()
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
        
        promise_1.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancelOnFirst_WhileSecondSucceeded() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise_1.cancel()
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancelOnSecond_WhileFirstSucceeded() {
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise_2.cancel()
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenCompletingWithValueOnBoth_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.fulfill(with: 0)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        
        promise_2.fulfill(with: 0)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        
        XCTAssertEqual(workLog, [.then(testDescription(of: [0, 0])), .resulted, .always])
    }
    
    func testShouldHandleValue_WhenCompletingWithValueOnBothReversed_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.fulfill(with: 0)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        
        promise_1.fulfill(with: 0)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        
        XCTAssertEqual(workLog, [.then(testDescription(of: [0, 0])), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithErrorOnFirst_WhileSecondWaiting_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.break(with: testError)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
        
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithErrorOnSecond_WhileFirstWaiting_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.break(with: testError)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
        
        promise_1.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithErrorOnFirst_WhileSecondSucceeded_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise_1.break(with: testError)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithErrorOnSecond_WhileFirstSucceeded_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise_2.break(with: testError)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancelOnFirst_WhileSecondWaiting_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.cancel()
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
        
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancelOnSecond_WhileFirstWaiting_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.cancel()
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
        
        promise_1.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancelOnFirst_WhileSecondSucceeded_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise_1.cancel()
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancelOnSecond_WhileFirstSucceeded_UsingArray() {
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise_1.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise_2.cancel()
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    // MARK: -
    // MARK: completed
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValueOnBoth() {
        promise_1.fulfill(with: 0)
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)

        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.then(testDescription(of: (0, 0))), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithErrorOnFirst_WhileSecondWaiting() {
        promise_1.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithErrorOnSecond_WhileFirstWaiting() {
        promise_2.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithErrorOnFirst_WhileSecondSucceeded() {
        promise_1.break(with: testError)
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithErrorOnSecond_WhileFirstSucceeded() {
        promise_1.fulfill(with: 0)
        promise_2.break(with: testError)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancelOnFirst_WhileSecondWaiting() {
        promise_1.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancelOnSecond_WhileFirstWaiting() {
        promise_2.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancelOnFirst_WhileSecondSucceeded() {
        promise_1.cancel()
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancelOnSecond_WhileFirstSucceeded() {
        promise_1.fulfill(with: 0)
        promise_2.cancel()
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip(promise_1.future, promise_2.future)
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValueOnBoth_UsingArray() {
        promise_1.fulfill(with: 0)
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.then(testDescription(of: [0, 0])), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithErrorOnFirst_WhileSecondWaiting_UsingArray() {
        promise_1.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithErrorOnSecond_WhileFirstWaiting_UsingArray() {
        promise_2.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithErrorOnFirst_WhileSecondSucceeded_UsingArray() {
        promise_1.break(with: testError)
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithErrorOnSecond_WhileFirstSucceeded_UsingArray() {
        promise_1.fulfill(with: 0)
        promise_2.break(with: testError)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancelOnFirst_WhileSecondWaiting_UsingArray() {
        promise_1.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancelOnSecond_WhileFirstWaiting_UsingArray() {
        promise_2.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancelOnFirst_WhileSecondSucceeded_UsingArray() {
        promise_1.cancel()
        promise_2.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancelOnSecond_WhileFirstSucceeded_UsingArray() {
        promise_1.fulfill(with: 0)
        promise_2.cancel()
        XCTAssertEqual(worker.execute(), 2)
        XCTAssert(workLog.isEmpty)
        
        zip([promise_1.future, promise_2.future])
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    // MARK: -
    // MARK: thread safety
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenCompletingWithValueOnManyThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var promises: [Promise<Int>] = Array.init()
            promises.reserveCapacity(101)
            for _ in 0...100 {
                promises.append(Promise<Int>())
            }
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: RecursiveLock = .init()
            let lock_2: RecursiveLock = .init()
            let lock_3: RecursiveLock = .init()
            let lock_4: RecursiveLock = .init()
            var counter_1 = 0
            var counter_2 = 0
            var counter_3 = 0
            
            dispatchQueue.async {
                lock_1.lock()
                for i in 1...100 {
                    zip(promises[i-1].future, promises[i].future).always {
                        counter_1 += 1
                    }
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                for i in 1...100 {
                    zip(promises[i-1].future, promises[i].future).always {
                        counter_2 += 1
                    }
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                for i in 1...100 {
                    zip(promises[i-1].future, promises[i].future).always {
                        counter_3 += 1
                    }
                }
                lock_3.unlock()
            }
            
            dispatchQueue.async {
                lock_4.lock()
                for promise in promises {
                    promise.fulfill(with: 0)
                }
                lock_4.unlock()
            }
            
            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            lock_4.lock()
            
            XCTAssertEqual(counter_1 + counter_2 + counter_3, 300, "Calls count not matching expected")
            complete()
        }
    }
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenCompletingWithErrorOnManyThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var promises: [Promise<Int>] = Array.init()
            promises.reserveCapacity(101)
            for _ in 0...100 {
                promises.append(Promise<Int>())
            }
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: RecursiveLock = .init()
            let lock_2: RecursiveLock = .init()
            let lock_3: RecursiveLock = .init()
            let lock_4: RecursiveLock = .init()
            var counter_1 = 0
            var counter_2 = 0
            var counter_3 = 0
            
            dispatchQueue.async {
                lock_1.lock()
                for i in 1...100 {
                    zip(promises[i-1].future, promises[i].future).always {
                        counter_1 += 1
                    }
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                for i in 1...100 {
                    zip(promises[i-1].future, promises[i].future).always {
                        counter_2 += 1
                    }
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                for i in 1...100 {
                    zip(promises[i-1].future, promises[i].future).always {
                        counter_3 += 1
                    }
                }
                lock_3.unlock()
            }
            
            dispatchQueue.async {
                lock_4.lock()
                for promise in promises {
                    promise.break(with: testError)
                }
                lock_4.unlock()
            }
            
            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            lock_4.lock()
            
            XCTAssertEqual(counter_1 + counter_2 + counter_3, 300, "Calls count not matching expected")
            complete()
        }
    }
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenCompletingWithCancelOnManyThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var promises: [Promise<Int>] = Array.init()
            promises.reserveCapacity(101)
            for _ in 0...100 {
                promises.append(Promise<Int>())
            }
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: RecursiveLock = .init()
            let lock_2: RecursiveLock = .init()
            let lock_3: RecursiveLock = .init()
            let lock_4: RecursiveLock = .init()
            var counter_1 = 0
            var counter_2 = 0
            var counter_3 = 0
            
            dispatchQueue.async {
                lock_1.lock()
                for i in 1...100 {
                    zip(promises[i-1].future, promises[i].future).always {
                        counter_1 += 1
                    }
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                for i in 1...100 {
                    zip(promises[i-1].future, promises[i].future).always {
                        counter_2 += 1
                    }
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                for i in 1...100 {
                    zip(promises[i-1].future, promises[i].future).always {
                        counter_3 += 1
                    }
                }
                lock_3.unlock()
            }
            
            dispatchQueue.async {
                lock_4.lock()
                for promise in promises {
                    promise.cancel()
                }
                lock_4.unlock()
            }
            
            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            lock_4.lock()
            
            XCTAssertEqual(counter_1 + counter_2 + counter_3, 300, "Calls count not matching expected")
            complete()
        }
    }
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenCompletingWithValueOnManyThreads_UsingArray() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var promises: [Promise<Int>] = Array.init()
            promises.reserveCapacity(101)
            for _ in 0...100 {
                promises.append(Promise<Int>())
            }
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: RecursiveLock = .init()
            let lock_2: RecursiveLock = .init()
            let lock_3: RecursiveLock = .init()
            let lock_4: RecursiveLock = .init()
            var counter_1 = 0
            var counter_2 = 0
            var counter_3 = 0
            
            dispatchQueue.async {
                lock_1.lock()
                zip(promises.map { $0.future }).always {
                    counter_1 += 1
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                zip(promises.map { $0.future }).always {
                    counter_2 += 1
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                zip(promises.map { $0.future }).always {
                    counter_3 += 1
                }
                lock_3.unlock()
            }
            
            dispatchQueue.async {
                lock_4.lock()
                for promise in promises {
                    promise.fulfill(with: 0)
                }
                lock_4.unlock()
            }
            
            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            lock_4.lock()
            
            XCTAssertEqual(counter_1 + counter_2 + counter_3, 3, "Calls count not matching expected")
            complete()
        }
    }
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenCompletingWithErrorOnManyThreads_UsingArray() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var promises: [Promise<Int>] = Array.init()
            promises.reserveCapacity(101)
            for _ in 0...100 {
                promises.append(Promise<Int>())
            }
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: RecursiveLock = .init()
            let lock_2: RecursiveLock = .init()
            let lock_3: RecursiveLock = .init()
            let lock_4: RecursiveLock = .init()
            var counter_1 = 0
            var counter_2 = 0
            var counter_3 = 0
            
            dispatchQueue.async {
                lock_1.lock()
                zip(promises.map { $0.future }).always {
                    counter_1 += 1
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                zip(promises.map { $0.future }).always {
                    counter_2 += 1
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                zip(promises.map { $0.future }).always {
                    counter_3 += 1
                }
                lock_3.unlock()
            }
            
            dispatchQueue.async {
                lock_4.lock()
                for promise in promises {
                    promise.break(with: testError)
                }
                lock_4.unlock()
            }
            
            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            lock_4.lock()
            
            XCTAssertEqual(counter_1 + counter_2 + counter_3, 3, "Calls count not matching expected")
            complete()
        }
    }
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenCompletingWithCancelOnManyThreads_UsingArray() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var promises: [Promise<Int>] = Array.init()
            promises.reserveCapacity(101)
            for _ in 0...100 {
                promises.append(Promise<Int>())
            }
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: RecursiveLock = .init()
            let lock_2: RecursiveLock = .init()
            let lock_3: RecursiveLock = .init()
            let lock_4: RecursiveLock = .init()
            var counter_1 = 0
            var counter_2 = 0
            var counter_3 = 0
            
            dispatchQueue.async {
                lock_1.lock()
                zip(promises.map { $0.future }).always {
                    counter_1 += 1
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                zip(promises.map { $0.future }).always {
                    counter_2 += 1
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                zip(promises.map { $0.future }).always {
                    counter_3 += 1
                }
                lock_3.unlock()
            }
            
            dispatchQueue.async {
                lock_4.lock()
                for promise in promises {
                    promise.cancel()
                }
                lock_4.unlock()
            }
            
            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            lock_4.lock()
            
            XCTAssertEqual(counter_1 + counter_2 + counter_3, 3, "Calls count not matching expected")
            complete()
        }
    }
}

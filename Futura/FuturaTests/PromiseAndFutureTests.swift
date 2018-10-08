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

class PromiseAndFutureTestsTests: XCTestCase {
    
    var worker: TestWorker = .init()
    var workLog: WorkLog = .init()
    var promise: Promise<Int> = .init()
    
    override func setUp() {
        super.setUp()
        worker = .init()
        workLog = .init()
        promise = .init(executionContext: .explicit(worker))
    }
    
    // MARK: -
    // MARK: completing
    
    func testShouldHandleValue_WhenCompletingWithValue() {
        promise.future
            .then { value in
                self.workLog.log(.then(testDescription(of: value)))
            }
            .fail { reason in
                self.workLog.log(.fail(testDescription(of: reason)))
            }
            .resulted {
                self.workLog.log(.resulted)
            }
            .always {
                self.workLog.log(.always)
        }
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithError() {
        promise.future
            .then { value in
                self.workLog.log(.then(testDescription(of: value)))
            }
            .fail { reason in
                self.workLog.log(.fail(testDescription(of: reason)))
            }
            .resulted {
                self.workLog.log(.resulted)
            }
            .always {
                self.workLog.log(.always)
        }
        XCTAssert(worker.isEmpty)
        
        promise.break(with: testError)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancel() {
        promise.future
            .then { value in
                self.workLog.log(.then(testDescription(of: value)))
            }
            .fail { reason in
                self.workLog.log(.fail(testDescription(of: reason)))
            }
            .resulted {
                self.workLog.log(.resulted)
            }
            .always {
                self.workLog.log(.always)
        }
        XCTAssert(worker.isEmpty)
        
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingRecovery() {
        promise.future
            .recover { error in
                self.workLog.log(.recover)
                return 0 as Int
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleValue_WhenCompletingWithError_UsingRecovery() {
        promise.future
            .recover { error in
                self.workLog.log(.recover)
                return 0 as Int
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.break(with: testError)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.recover, .then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingThrowingRecovery() {
        promise.future
            .recover { error in
                self.workLog.log(.recover)
                throw error
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.break(with: testError)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.recover, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancel_UsingRecovery() {
        promise.future
            .recover { error in
                self.workLog.log(.recover)
                throw error
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingCatch() {
        promise.future
            .catch { error in
                self.workLog.log(.catch)
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithError_UsingCatch() {
        promise.future
            .catch { error in
                self.workLog.log(.catch)
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.break(with: testError)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.catch, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingThrowingCatch() {
        promise.future
            .catch { error in
                self.workLog.log(.catch)
                throw error
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.break(with: testError)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.catch, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancel_UsingCatch() {
        promise.future
            .catch { error in
                self.workLog.log(.catch)
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingMap() {
        promise.future
            .map { (value: Int) -> Int in
                self.workLog.log(.map)
                return value + 1
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.map, .then(testDescription(of: 1)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithValue_UsingThrowingMap() {
        promise.future
            .map { (value: Int) -> Int in
                self.workLog.log(.map)
                throw testError
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.map, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingMap() {
        promise.future
            .map { (value: Int) -> Int in
                self.workLog.log(.map)
                return value + 1
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.break(with: testError)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancel_UsingMap() {
        promise.future
            .map { (value: Int) -> Int in
                self.workLog.log(.map)
                return value + 1
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingFlatMapWithSuccess() {
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                return Future<Int>(succeededWith: value + 1)
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.flatMap, .then(testDescription(of: 1)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithValue_UsingThrowingFlatMap() {
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                throw testError
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.flatMap, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithValue_UsingFlatMapWithError() {
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                return Future<Int>(failedWith: testError)
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.flatMap, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithValue_UsingFlatMapWithCancel() {
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                let inner = Promise<Int>().future
                inner.cancel()
                return inner
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.flatMap, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingFlatMap() {
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                return Future<Int>(succeededWith: value + 1)
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.break(with: testError)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancel_UsingFlatMap() {
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                return Future<Int>(succeededWith: value + 1)
            }
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingClone() {
        promise.future
            .clone()
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingClone() {
        promise.future
            .clone()
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.break(with: testError)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancel_UsingClone() {
        promise.future
            .clone()
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingContextSwitch() {
        let otherWorker: TestWorker = .init()
        
        promise.future
            .switch(to: otherWorker)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        XCTAssert(otherWorker.isEmpty)
        
        promise.fulfill(with: 0)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(otherWorker.execute(), 1)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingContextSwitch() {
        let otherWorker: TestWorker = .init()
        
        promise.future
            .switch(to: otherWorker)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        XCTAssert(otherWorker.isEmpty)
        
        promise.break(with: testError)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(otherWorker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenCompletingWithCancel_UsingContextSwitch() {
        let otherWorker: TestWorker = .init()
        
        promise.future
            .switch(to: otherWorker)
            .logResults(with: workLog)
        XCTAssert(worker.isEmpty)
        XCTAssert(otherWorker.isEmpty)
        
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(otherWorker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    // MARK: -
    // MARK: completed
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .then { value in
                self.workLog.log(.then(testDescription(of: value)))
            }
            .fail { reason in
                self.workLog.log(.fail(testDescription(of: reason)))
            }
            .resulted {
                self.workLog.log(.resulted)
            }
            .always {
                self.workLog.log(.always)
        }
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 4)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError() {
        promise.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .then { value in
                self.workLog.log(.then(testDescription(of: value)))
            }
            .fail { reason in
                self.workLog.log(.fail(testDescription(of: reason)))
            }
            .resulted {
                self.workLog.log(.resulted)
            }
            .always {
                self.workLog.log(.always)
        }
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 4)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancel() {
        promise.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .then { value in
                self.workLog.log(.then(testDescription(of: value)))
            }
            .fail { reason in
                self.workLog.log(.fail(testDescription(of: reason)))
            }
            .resulted {
                self.workLog.log(.resulted)
            }
            .always {
                self.workLog.log(.always)
        }
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 4)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingRecovery() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .recover { error in
                self.workLog.log(.recover)
                return 0 as Int
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithError_UsingRecovery() {
        promise.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .recover { error in
                self.workLog.log(.recover)
                return 0 as Int
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.recover, .then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingThrowingRecovery() {
        promise.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .recover { error in
                self.workLog.log(.recover)
                throw error
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.recover, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancel_UsingRecovery() {
        promise.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .recover { error in
                self.workLog.log(.recover)
                throw error
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingCatch() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .catch { error in
                self.workLog.log(.catch)
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithError_UsingCatch() {
        promise.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .catch { error in
                self.workLog.log(.catch)
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.catch, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingThrowingCatch() {
        promise.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .catch { error in
                self.workLog.log(.catch)
                throw error
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.catch, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancel_UsingCatch() {
        promise.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .catch { error in
                self.workLog.log(.catch)
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingMap() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .map { (value: Int) -> Int in
                self.workLog.log(.map)
                return value + 1
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.map, .then(testDescription(of: 1)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithValue_UsingThrowingMap() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .map { (value: Int) -> Int in
                self.workLog.log(.map)
                throw testError
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.map, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingMap() {
        promise.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .map { (value: Int) -> Int in
                self.workLog.log(.map)
                return value + 1
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancel_UsingMap() {
        promise.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .map { (value: Int) -> Int in
                self.workLog.log(.map)
                return value + 1
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingFlatMapWithSuccess() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                return Future<Int>(succeededWith: value + 1)
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.flatMap, .then(testDescription(of: 1)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithValue_UsingThrowingFlatMap() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                throw testError
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.flatMap, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithValue_UsingFlatMapWithError() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                return Future<Int>(failedWith: testError)
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.flatMap, .fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithValue_UsingFlatMapWithCancel() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                let inner = Promise<Int>().future
                inner.cancel()
                return inner
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.flatMap, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingFlatMap() {
        promise.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                return Future<Int>(succeededWith: value + 1)
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancel_UsingFlatMap() {
        promise.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                self.workLog.log(.flatMap)
                return Future<Int>(succeededWith: value + 1)
            }
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingClone() {
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .clone()
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingClone() {
        promise.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .clone()
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancel_UsingClone() {
        promise.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .clone()
            .logResults(with: workLog)
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 2)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingContextSwitch() {
        let otherWorker: TestWorker = .init()
        
        promise.fulfill(with: 0)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .switch(to: otherWorker)
            .logResults(with: workLog)
        
        XCTAssert(otherWorker.isEmpty)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(otherWorker.execute(), 1)
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingContextSwitch() {
        let otherWorker: TestWorker = .init()
        
        promise.break(with: testError)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .switch(to: otherWorker)
            .logResults(with: workLog)
        
        XCTAssert(otherWorker.isEmpty)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(otherWorker.execute(), 1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithCancel_UsingContextSwitch() {
        let otherWorker: TestWorker = .init()
        
        promise.cancel()
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        
        promise.future
            .switch(to: otherWorker)
            .logResults(with: workLog)
        
        XCTAssert(otherWorker.isEmpty)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(otherWorker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldCompleteOnce_WhenAlreadySucceeded() {
        promise.future
            .always {
                self.workLog.log(.always)
        }
        
        promise.fulfill(with: 0)
        
        promise.fulfill(with: 0)
        promise.break(with: testError)
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldCompleteOnce_WhenAlreadyFailed() {
        promise.future
            .always {
                self.workLog.log(.always)
        }
        
        promise.break(with: testError)
        
        promise.fulfill(with: 0)
        promise.break(with: testError)
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldCompleteOnce_WhenAlreadyCanceled() {
        promise.future
            .always {
                self.workLog.log(.always)
        }
        
        promise.cancel()
        
        promise.fulfill(with: 0)
        promise.break(with: testError)
        promise.cancel()
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    // MARK: -
    // MARK: workers
    
    func testShouldPropagateExecutionContext_WhenAlreadyCompletedWithValue_UsingTransformations() {
        promise.fulfill(with: 0)
        
        var currentFuture = promise.future
        
        XCTAssertEqual(worker.execute(), 1)
        
        let cloneWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: cloneWorker)
                .clone()
        
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(cloneWorker.execute(), 2)
        
        let mapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: mapWorker)
                .map { value in
                    self.workLog.log(.map)
                    return value
        }
        
        XCTAssertEqual(cloneWorker.execute(), 1)
        XCTAssertEqual(mapWorker.execute(), 2)
        
        let flatMapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: flatMapWorker)
                .flatMap { value in
                    self.workLog.log(.flatMap)
                    return .init(succeededWith: value)
        }
        
        XCTAssertEqual(mapWorker.execute(), 1)
        XCTAssertEqual(flatMapWorker.execute(), 2)
        
        let recoverWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: recoverWorker)
                .recover { error in
                    self.workLog.log(.recover)
                    throw error
        }
        
        XCTAssertEqual(flatMapWorker.execute(), 1)
        XCTAssertEqual(recoverWorker.execute(), 2)
        
        let catchWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: catchWorker)
                .catch { error in
                    self.workLog.log(.catch)
                    throw error
        }
        
        XCTAssertEqual(recoverWorker.execute(), 1)
        XCTAssertEqual(catchWorker.execute(), 2)
        
        XCTAssert(worker.isEmpty)
        XCTAssert(cloneWorker.isEmpty)
        XCTAssert(mapWorker.isEmpty)
        XCTAssert(flatMapWorker.isEmpty)
        XCTAssert(recoverWorker.isEmpty)
        XCTAssert(catchWorker.isEmpty)
        XCTAssertEqual(workLog, [.map, .flatMap])
    }
    
    func testShouldPropagateExecutionContext_WhenAlreadyCompletedWithError_UsingTransformations() {
        promise.break(with: TestError())
        
        var currentFuture = promise.future
        
        XCTAssertEqual(worker.execute(), 1)
        
        let cloneWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: cloneWorker)
                .clone()
        
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(cloneWorker.execute(), 2)
        
        let mapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: mapWorker)
                .map { value in
                    self.workLog.log(.map)
                    return value
        }
        
        XCTAssertEqual(cloneWorker.execute(), 1)
        XCTAssertEqual(mapWorker.execute(), 2)
        
        let flatMapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: flatMapWorker)
                .flatMap { value in
                    self.workLog.log(.flatMap)
                    return .init(succeededWith: value)
        }
        
        XCTAssertEqual(mapWorker.execute(), 1)
        XCTAssertEqual(flatMapWorker.execute(), 2)
        
        let recoverWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: recoverWorker)
                .recover { error in
                    self.workLog.log(.recover)
                    throw error
        }
        
        XCTAssertEqual(flatMapWorker.execute(), 1)
        XCTAssertEqual(recoverWorker.execute(), 2)
        
        let catchWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: catchWorker)
                .catch { error in
                    self.workLog.log(.catch)
                    throw error
        }
        
        XCTAssertEqual(recoverWorker.execute(), 1)
        XCTAssertEqual(catchWorker.execute(), 2)
        
        XCTAssert(worker.isEmpty)
        XCTAssert(cloneWorker.isEmpty)
        XCTAssert(mapWorker.isEmpty)
        XCTAssert(flatMapWorker.isEmpty)
        XCTAssert(recoverWorker.isEmpty)
        XCTAssert(catchWorker.isEmpty)
        XCTAssertEqual(workLog, [.recover, .catch])
    }
    
    func testShouldPropagateExecutionContext_WhenAlreadyCanceled_UsingTransformations() {
        promise.cancel()
        
        var currentFuture = promise.future
        
        XCTAssertEqual(worker.execute(), 1)
        
        let cloneWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: cloneWorker)
                .clone()
        
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(cloneWorker.execute(), 2)
        
        let mapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: mapWorker)
                .map { value in
                    self.workLog.log(.map)
                    return value
        }
        
        XCTAssertEqual(cloneWorker.execute(), 1)
        XCTAssertEqual(mapWorker.execute(), 2)
        
        let flatMapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: flatMapWorker)
                .flatMap { value in
                    self.workLog.log(.flatMap)
                    return .init(succeededWith: value)
        }
        
        XCTAssertEqual(mapWorker.execute(), 1)
        XCTAssertEqual(flatMapWorker.execute(), 2)
        
        let recoverWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: recoverWorker)
                .recover { error in
                    self.workLog.log(.recover)
                    throw error
        }
        
        XCTAssertEqual(flatMapWorker.execute(), 1)
        XCTAssertEqual(recoverWorker.execute(), 2)
        
        let catchWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: catchWorker)
                .catch { error in
                    self.workLog.log(.catch)
                    throw error
        }
        
        XCTAssertEqual(recoverWorker.execute(), 1)
        XCTAssertEqual(catchWorker.execute(), 2)
        
        XCTAssert(worker.isEmpty)
        XCTAssert(cloneWorker.isEmpty)
        XCTAssert(mapWorker.isEmpty)
        XCTAssert(flatMapWorker.isEmpty)
        XCTAssert(recoverWorker.isEmpty)
        XCTAssert(catchWorker.isEmpty)
        XCTAssert(workLog.isEmpty)
    }
    
    // MARK: -
    // MARK: memory and init
    
    func testShouldInitializeSucceeded() {
        let promise: Promise<Int> = Promise<Int>(succeededWith: 0)
        promise.future.logResults(with: workLog)
        
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
        
        workLog = .init()
        
        let future: Future<Int> = Future<Int>(succeededWith: 0)
        future.logResults(with: workLog)
        
        XCTAssertEqual(workLog, [.then(testDescription(of: 0)), .resulted, .always])
    }
    
    func testShouldInitializeFailed() {
        let promise: Promise<Int> = Promise<Int>(failedWith: testError)
        promise.future.logResults(with: workLog)
        
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
        
        workLog = .init()
        
        let future: Future<Int> = Future<Int>(failedWith: testError)
        future.logResults(with: workLog)
        
        XCTAssertEqual(workLog, [.fail(testErrorDescription), .resulted, .always])
    }
    
    func testShouldDeallocateWithoutHandlers() {
        var promise: Promise<Int>? = Promise<Int>(succeededWith: 0)
        weak var future = promise?.future
        
        XCTAssertNotNil(future, "Future deallocated while responsible Promise still available")
        
        promise = nil
        
        XCTAssertNil(future, "Future not deallocated while responsible Promise dealocated")
    }
    
    func testShouldDeallocateWithHandlersWithoutReference() {
        var promise: Promise<Int>? = Promise<Int>(succeededWith: 0)
        weak var future = promise?.future
        
        future?.always({}).clone().always({}).clone().always({}).clone().always({})
        
        XCTAssertNotNil(future, "Future deallocated while responsible Promise still available")
        
        promise = nil
        
        XCTAssertNil(future, "Future not deallocated while responsible Promise dealocated")
    }
    
    func testShouldDeallocateWithHandlersWithReference() {
        var promise: Promise<Int>? = Promise<Int>(succeededWith: 0)
        weak var future = promise?.future
        var child = future?.clone()
        weak var weakChild = child
        let strongChild = child?.clone()
        
        XCTAssertNotNil(future, "Future deallocated while responsible Promise still available")
        XCTAssertNotNil(weakChild, "Future deallocated while parent Future still available")
        
        promise = nil
        child = nil
        
        XCTAssertNil(future, "Future not deallocated while responsible Promise dealocated")
        XCTAssertNil(weakChild, "Future not deallocated while parent Future dealocated")
        XCTAssertNotNil(strongChild)
    }
    
    func testShouldHandleCancel_WhenDeallocating() {
        var promise: Promise<Int>? = .init(executionContext: .explicit(worker))
        
        promise!.future.logResults(with: workLog)
        XCTAssert(workLog.isEmpty)
        XCTAssert(worker.isEmpty)
        
        promise = nil
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 1)
        XCTAssertEqual(workLog, [.always])
    }
    
    func testShouldExecuteHandlers_WhenDeallocating() {
        var promise: Promise<Int>? = .init(executionContext: .explicit(worker))
        
        promise!.future.clone().clone().logResults(with: workLog)
        XCTAssert(workLog.isEmpty)
        XCTAssert(worker.isEmpty)
        
        promise = nil
        
        XCTAssert(workLog.isEmpty)
        XCTAssertEqual(worker.execute(), 3)
        XCTAssertEqual(workLog, [.always])
    }
    
    // MARK: -
    // MARK: thread safety
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenAccessingOnManyThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future: Future<Int> = Future<Int>(succeededWith: 0)
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: Lock = Lock()
            let lock_2: Lock = Lock()
            let lock_3: Lock = Lock()
            var counter = 0
            
            dispatchQueue.async {
                lock_1.lock()
                for _ in 0..<100 {
                    future.always {
                        counter += 1
                    }
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                for _ in 0..<100 {
                    future.always {
                        counter += 1
                    }
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                for _ in 0..<100 {
                    future.always {
                        counter += 1
                    }
                }
                lock_3.unlock()
            }
            
            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            
            XCTAssertEqual(counter, 300, "Calls count not matching expected")
            complete()
        }
    }
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenTransformingOnManyThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future: Future<Int> = Future<Int>(succeededWith: 0)
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: Lock = Lock()
            let lock_2: Lock = Lock()
            let lock_3: Lock = Lock()
            var counter_1 = 0
            var counter_2 = 0
            var counter_3 = 0
            
            dispatchQueue.async {
                lock_1.lock()
                for _ in 0..<100 {
                    future
                        .clone()
                        .map { $0 }
                        .flatMap { .init(succeededWith: $0) }
                        .recover { throw $0 }
                        .catch { throw $0 }
                        .always { counter_1 += 1 }
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                for _ in 0..<100 {
                    future
                        .clone()
                        .map { $0 }
                        .flatMap { .init(succeededWith: $0) }
                        .recover { throw $0 }
                        .catch { throw $0 }
                        .always { counter_2 += 1 }
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                for _ in 0..<100 {
                    future
                        .clone()
                        .map { $0 }
                        .flatMap { .init(succeededWith: $0) }
                        .recover { throw $0 }
                        .catch { throw $0 }
                        .always { counter_3 += 1 }
                }
                lock_3.unlock()
            }
            
            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            
            XCTAssertEqual(counter_1 + counter_2 + counter_3, 300, "Calls count not matching expected")
            complete()
        }
    }
}

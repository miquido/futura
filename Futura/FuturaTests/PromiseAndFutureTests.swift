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
    
    // MARK: -
    // MARK: completing
    
    func testShouldHandleValue_WhenCompletingWithValue() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.future
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithError() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.future
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenCanceling() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingRecovery() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.future
            .recover { error in
                workLog.log(.recover)
                XCTFail("Should not be called")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenCompletingWithError_UsingRecovery() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedError: Error = TestError()
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.recover, .then, .resulted, .always]
        
        promise.future
            .recover { error in
                workLog.log(.recover)
                XCTAssert(error is TestError, "Future error not matching expected. Expected: \(expectedError) Recieved: \(error)")
                return expectedResult
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Recovered future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: expectedError)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.recover], "Work log not matching expected. Expected: \(WorkLog(.recover)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingThrowingRecovery() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.recover, .fail, .resulted, .always]
        
        promise.future
            .recover { error in
                workLog.log(.recover)
                XCTAssert(error is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(error)")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.recover], "Work log not matching expected. Expected: \(WorkLog(.recover)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenCanceling_UsingRecovery() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .recover { error in
                workLog.log(.recover)
                XCTFail("Should not be called")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingCatch() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.future
            .catch { error in
                workLog.log(.catch)
                XCTFail("Should not be called")
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenCompletingWithError_UsingCatch() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.catch, .always]
        
        promise.future
            .catch { error in
                workLog.log(.catch)
                XCTAssert(error is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(error)")
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.catch], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingThrowingCatch() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.catch, .fail, .resulted, .always]
        
        promise.future
            .catch { error in
                workLog.log(.catch)
                XCTAssert(error is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(error)")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.catch], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenCanceling_UsingCatch() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .catch { error in
                workLog.log(.catch)
                XCTFail("Should not be called")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 1
        let expectedWorkLog: WorkLog = [.map, .then, .resulted, .always]
        
        promise.future
            .map { (value: Int) -> Int in
                workLog.log(.map)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                return value + 1
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Mapped future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.map], "Work log not matching expected. Expected: \(WorkLog(.map)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithValue_UsingThrowingMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.map, .fail, .resulted, .always]
        
        promise.future
            .map { (value: Int) -> Int in
                workLog.log(.map)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                throw expectedResult
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.map], "Work log not matching expected. Expected: \(WorkLog(.map)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenCanceling_UsingMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .map { (value: Int) -> Int in
                workLog.log(.map)
                XCTFail("Should not be called")
                return value
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.future
            .map { (value: Int) -> Int in
                workLog.log(.map)
                XCTFail("Should not be called")
                return value
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingFlatMapWithSuccess() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 1
        let expectedWorkLog: WorkLog = [.flatMap, .then, .resulted, .always]
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                return Future<Int>(succeededWith: value + 1)
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Mapped future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithValue_UsingThrowingFlatMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.flatMap, .fail, .resulted, .always]
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                throw expectedResult
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingFlatMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTFail("Should not be called")
                return Future<Int>(succeededWith: value)
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithValue_UsingFlatMapWithError() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.flatMap, .fail, .resulted, .always]
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                return Future<Int>(failedWith: expectedResult)
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenCompletingWithValue_UsingFlatMapWithCancel() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.flatMap, .always]
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                let inner: Future<Int> = Promise<Int>().future
                inner.cancel()
                return inner
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenCanceling_UsingFlatMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTFail("Should not be called")
                return .init(succeededWith: value)
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingClone() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.future
            .clone()
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Mapped future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenCanceling_UsingClone() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .clone()
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingClone() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.future
            .clone()
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingContextSwitch() {
        let worker: TestWorker = .init()
        let otherWorker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.future
            .switch(to: otherWorker)
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Mapped future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(otherWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        otherWorker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(otherWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenCanceling_UsingContextSwitch() {
        let worker: TestWorker = .init()
        let otherWorker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .switch(to: otherWorker)
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(otherWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        otherWorker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(otherWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingContextSwitch() {
        let worker: TestWorker = .init()
        let otherWorker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.future
            .switch(to: otherWorker)
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(otherWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        otherWorker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(otherWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    // MARK: -
    // MARK: completed
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Promise value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 4, "Worker should recieve task for each handler. Expected: \(4) Recieved: \(worker.taskCount)")
        
        worker.executeAll()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Promise error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 4, "Worker should recieve task for each handler. Expected: \(4) Recieved: \(worker.taskCount)")
        
        worker.executeAll()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenAlreadyCanceled() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 4, "Worker should recieve task for each handler. Expected: \(4) Recieved: \(worker.taskCount)")
        
        worker.executeAll()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingRecovery() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .recover { error in
                workLog.log(.recover)
                XCTFail("Should not be called")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after performing transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithError_UsingRecovery() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedError: Error = TestError()
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.recover, .then, .resulted, .always]
        
        promise.break(with: expectedError)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .recover { error in
                workLog.log(.recover)
                XCTAssert(error is TestError, "Future error not matching expected. Expected: \(expectedError) Recieved: \(error)")
                return expectedResult
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Recovered future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.recover], "Work log not matching expected. Expected: \(WorkLog(.recover)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingThrowingRecovery() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.recover, .fail, .resulted, .always]
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .recover { error in
                workLog.log(.recover)
                XCTAssert(error is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(error)")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.recover], "Work log not matching expected. Expected: \(WorkLog(.recover)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenAlreadyCanceled_UsingRecovery() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .recover { error in
                workLog.log(.recover)
                XCTFail("Should not be called")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
            }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingCatch() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .catch { error in
                workLog.log(.catch)
                XCTFail("Should not be called")
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithError_UsingCatch() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.catch, .always]
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .catch { error in
                workLog.log(.catch)
                XCTAssert(error is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(error)")
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.catch], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingThrowingCatch() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.catch, .fail, .resulted, .always]
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .catch { error in
                workLog.log(.catch)
                XCTAssert(error is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(error)")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.catch], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenAlreadyCanceled_UsingCatch() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .catch { error in
                workLog.log(.catch)
                XCTFail("Should not be called")
                throw error
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 1
        let expectedWorkLog: WorkLog = [.map, .then, .resulted, .always]
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .map { (value: Int) -> Int in
                workLog.log(.map)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                return value + 1
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Mapped future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.map], "Work log not matching expected. Expected: \(WorkLog(.map)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithValue_UsingThrowingMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.map, .fail, .resulted, .always]
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .map { (value: Int) -> Int in
                workLog.log(.map)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                throw expectedResult
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.map], "Work log not matching expected. Expected: \(WorkLog(.map)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenAlreadyCanceled_UsingMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .map { (value: Int) -> Int in
                workLog.log(.map)
                XCTFail("Should not be called")
                return value
            }
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .map { (value: Int) -> Int in
                workLog.log(.map)
                XCTFail("Should not be called")
                return value
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingFlatMapWithSuccess() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 1
        let expectedWorkLog: WorkLog = [.flatMap, .then, .resulted, .always]
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                return Future<Int>(succeededWith: value + 1)
            }
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Mapped future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithValue_UsingThrowingFlatMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.flatMap, .fail, .resulted, .always]
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                throw expectedResult
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingFlatMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTFail("Should not be called")
                return Future<Int>(succeededWith: value)
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithValue_UsingFlatMapWithError() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.flatMap, .fail, .resulted, .always]
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                return Future<Int>(failedWith: expectedResult)
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenAlreadyCompletedWithValue_UsingFlatMapWithCancel() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.flatMap, .always]
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTAssert(value == 0, "Future value not matching expected. Expected: \(0) Recieved: \(value)")
                let inner: Future<Int> = Promise<Int>().future
                inner.cancel()
                return inner
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenAlreadyCanceled_UsingFlatMap() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .flatMap { (value: Int) -> Future<Int> in
                workLog.log(.flatMap)
                XCTFail("Should not be called")
                return .init(succeededWith: value)
            }
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
                XCTFail("Should not be called")
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingClone() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .clone()
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Mapped future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenAlreadyCanceled_UsingClone() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .clone()
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingClone() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .clone()
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenAlreadyCompletedWithValue_UsingContextSwitch() {
        let worker: TestWorker = .init()
        let otherWorker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Int = 0
        let expectedWorkLog: WorkLog = [.then, .resulted, .always]
        
        promise.fulfill(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .switch(to: otherWorker)
            .then { value in
                workLog.log(.then)
                XCTAssert(value == expectedResult, "Mapped future value not matching expected. Expected: \(expectedResult) Recieved: \(value)")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(otherWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        otherWorker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(otherWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleCancel_WhenAlreadyCanceled_UsingContextSwitch() {
        let worker: TestWorker = .init()
        let otherWorker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .switch(to: otherWorker)
            .then { value in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { _ in
                workLog.log(.fail)
                XCTFail("Should not be called")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(otherWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        otherWorker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(otherWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenAlreadyCompletedWithError_UsingContextSwitch() {
        let worker: TestWorker = .init()
        let otherWorker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedResult: Error = TestError()
        let expectedWorkLog: WorkLog = [.fail, .resulted, .always]
        
        promise.break(with: expectedResult)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.future
            .switch(to: otherWorker)
            .then { _ in
                workLog.log(.then)
                XCTFail("Should not be called")
            }
            .fail { reason in
                workLog.log(.fail)
                XCTAssert(reason is TestError, "Future error not matching expected. Expected: \(expectedResult) Recieved: \(reason)")
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(otherWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        otherWorker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(otherWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(otherWorker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldCompleteOnce_WhenAlreadySucceeded() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .always {
                workLog.log(.always)
            }
        
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(0) Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: TestError())
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldCompleteOnce_WhenAlreadyFailed() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .always {
                workLog.log(.always)
            }
        
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(0) Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.break(with: TestError())
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: TestError())
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldCompleteOnce_WhenAlreadyCanceled() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        
        let expectedWorkLog: WorkLog = [.always]
        
        promise.future
            .always {
                workLog.log(.always)
            }
        
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(0) Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        promise.break(with: TestError())
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise. Recieved: \(worker.taskCount)")
        
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    // MARK: -
    // MARK: workers
    
    func testShouldPropagateExecutionContext_WhenAlreadyCompletedWithValue_UsingTransformations() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        var currentFuture = promise.future
        let expectedWorkLog: WorkLog = [.map, .flatMap]
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let cloneWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: cloneWorker)
                .clone()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(cloneWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        cloneWorker.executeFirst()
        XCTAssert(cloneWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        cloneWorker.executeFirst()
        XCTAssert(cloneWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let mapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: mapWorker)
                .map { value in
                    workLog.log(.map)
                    return value
                }
        XCTAssert(cloneWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        cloneWorker.executeFirst()
        XCTAssert(mapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        mapWorker.executeFirst()
        XCTAssert(mapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [.map], "Work log not matching expected. Expected: \(WorkLog(.map)) Recieved: \(workLog)")
        
        mapWorker.executeFirst()
        XCTAssert(mapWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [.map], "Work log not matching expected. Expected: \(WorkLog(.map)) Recieved: \(workLog)")
        
        let flatMapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: flatMapWorker)
                .flatMap { value in
                    workLog.log(.flatMap)
                    return .init(succeededWith: value)
                }
        XCTAssert(mapWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [.map], "Work log not matching expected. Expected: \(WorkLog(.map)) Recieved: \(workLog)")
        
        mapWorker.executeFirst()
        XCTAssert(flatMapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [.map], "Work log not matching expected. Expected: \(WorkLog(.map)) Recieved: \(workLog)")
        
        flatMapWorker.executeFirst()
        XCTAssert(flatMapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        flatMapWorker.executeFirst()
        XCTAssert(flatMapWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        let recoverWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: recoverWorker)
                .recover { error in
                    workLog.log(.recover)
                    throw error
        }
        XCTAssert(flatMapWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        flatMapWorker.executeFirst()
        XCTAssert(recoverWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        recoverWorker.executeFirst()
        XCTAssert(recoverWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        recoverWorker.executeFirst()
        XCTAssert(recoverWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        let catchWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: catchWorker)
                .catch { error in
                    workLog.log(.catch)
                    throw error
                }
        XCTAssert(recoverWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        recoverWorker.executeFirst()
        XCTAssert(catchWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        catchWorker.executeFirst()
        XCTAssert(catchWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        catchWorker.executeFirst()
        XCTAssert(catchWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == [.map, .flatMap], "Work log not matching expected. Expected: \(WorkLog(.map, .flatMap)) Recieved: \(workLog)")
        
        
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(cloneWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(mapWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(mapWorker.taskCount)")
        XCTAssert(flatMapWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(recoverWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(catchWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldPropagateExecutionContext_WhenAlreadyCompletedWithError_UsingTransformations() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        var currentFuture = promise.future
        let expectedWorkLog: WorkLog = [.recover, .catch]
        
        promise.break(with: TestError())
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let cloneWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: cloneWorker)
                .clone()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(cloneWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        cloneWorker.executeFirst()
        XCTAssert(cloneWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        cloneWorker.executeFirst()
        XCTAssert(cloneWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let mapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: mapWorker)
                .map { value in
                    workLog.log(.map)
                    return value
        }
        XCTAssert(cloneWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        cloneWorker.executeFirst()
        XCTAssert(mapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        mapWorker.executeFirst()
        XCTAssert(mapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        mapWorker.executeFirst()
        XCTAssert(mapWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let flatMapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: flatMapWorker)
                .flatMap { value in
                    workLog.log(.flatMap)
                    return .init(succeededWith: value)
        }
        XCTAssert(mapWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        mapWorker.executeFirst()
        XCTAssert(flatMapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        flatMapWorker.executeFirst()
        XCTAssert(flatMapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        flatMapWorker.executeFirst()
        XCTAssert(flatMapWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let recoverWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: recoverWorker)
                .recover { error in
                    workLog.log(.recover)
                    throw error
        }
        XCTAssert(flatMapWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        flatMapWorker.executeFirst()
        XCTAssert(recoverWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        recoverWorker.executeFirst()
        XCTAssert(recoverWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [.recover], "Work log not matching expected. Expected: \(WorkLog(.recover)) Recieved: \(workLog)")
        
        recoverWorker.executeFirst()
        XCTAssert(recoverWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [.recover], "Work log not matching expected. Expected: \(WorkLog(.recover)) Recieved: \(workLog)")
        
        let catchWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: catchWorker)
                .catch { error in
                    workLog.log(.catch)
                    throw error
        }
        XCTAssert(recoverWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [.recover], "Work log not matching expected. Expected: \(WorkLog(.recover)) Recieved: \(workLog)")
        
        recoverWorker.executeFirst()
        XCTAssert(catchWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == [.recover], "Work log not matching expected. Expected: \(WorkLog(.recover)) Recieved: \(workLog)")
        
        catchWorker.executeFirst()
        XCTAssert(catchWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == [.recover, .catch], "Work log not matching expected. Expected: \(WorkLog(.recover, .catch)) Recieved: \(workLog)")
        
        catchWorker.executeFirst()
        XCTAssert(catchWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == [.recover, .catch], "Work log not matching expected. Expected: \(WorkLog(.recover, .catch)) Recieved: \(workLog)")
        
        
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(cloneWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(mapWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(mapWorker.taskCount)")
        XCTAssert(flatMapWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(recoverWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(catchWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldPropagateExecutionContext_WhenAlreadyCanceled_UsingTransformations() {
        let worker: TestWorker = .init()
        let workLog: WorkLog = .init()
        let promise: Promise<Int> = .init(executionContext: .explicit(worker))
        var currentFuture = promise.future
        let expectedWorkLog: WorkLog = []
        
        promise.cancel()
        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks after completing promise without handlers. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let cloneWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: cloneWorker)
                .clone()
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(cloneWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        cloneWorker.executeFirst()
        XCTAssert(cloneWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        cloneWorker.executeFirst()
        XCTAssert(cloneWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let mapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: mapWorker)
                .map { value in
                    workLog.log(.map)
                    return value
        }
        XCTAssert(cloneWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        cloneWorker.executeFirst()
        XCTAssert(mapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        mapWorker.executeFirst()
        XCTAssert(mapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        mapWorker.executeFirst()
        XCTAssert(mapWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let flatMapWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: flatMapWorker)
                .flatMap { value in
                    workLog.log(.flatMap)
                    return .init(succeededWith: value)
        }
        XCTAssert(mapWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(mapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        mapWorker.executeFirst()
        XCTAssert(flatMapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        flatMapWorker.executeFirst()
        XCTAssert(flatMapWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        flatMapWorker.executeFirst()
        XCTAssert(flatMapWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let recoverWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: recoverWorker)
                .recover { error in
                    workLog.log(.recover)
                    throw error
        }
        XCTAssert(flatMapWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        flatMapWorker.executeFirst()
        XCTAssert(recoverWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        recoverWorker.executeFirst()
        XCTAssert(recoverWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        recoverWorker.executeFirst()
        XCTAssert(recoverWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        let catchWorker: TestWorker = .init()
        currentFuture =
            currentFuture
                .switch(to: catchWorker)
                .catch { error in
                    workLog.log(.catch)
                    throw error
        }
        XCTAssert(recoverWorker.taskCount == 1, "Worker should recieve task after adding transforming handler. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        recoverWorker.executeFirst()
        XCTAssert(catchWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        catchWorker.executeFirst()
        XCTAssert(catchWorker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        catchWorker.executeFirst()
        XCTAssert(catchWorker.taskCount == 0, "Worker should complete tasks. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(cloneWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(cloneWorker.taskCount)")
        XCTAssert(mapWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(mapWorker.taskCount)")
        XCTAssert(flatMapWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(flatMapWorker.taskCount)")
        XCTAssert(recoverWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(recoverWorker.taskCount)")
        XCTAssert(catchWorker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(catchWorker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    // MARK: -
    // MARK: memory
    
    func testShouldDeallocate() {
        var promise: Promise<Int>? = Promise<Int>(succeededWith: 0)
        weak var future = promise?.future
        XCTAssert(future != nil, "Future deallocated while responsible Promise still available")
        promise = nil
        XCTAssert(future == nil, "Future not deallocated while responsible Promise dealocated")
    }
    
    func testShouldHandleCancel_WhenDeallocating() {
        #warning("Currently failing - crash on access to dealocated memory - not tested until fixed")
//        let worker: TestWorker = .init()
//        let workLog: WorkLog = .init()
//        var promise: Promise<Int>? = .init(executionContext: .explicit(worker))
//        let future: Future<Int> = promise!.future.clone()
//
//        let expectedWorkLog: WorkLog = [.always]
//
//        future
//            .then { _ in
//                workLog.log(.then)
//                XCTFail("Should not be called")
//            }
//            .fail { _ in
//                workLog.log(.fail)
//                XCTFail("Should not be called")
//            }
//            .resulted {
//                workLog.log(.resulted)
//                XCTFail("Should not be called")
//            }
//            .always {
//                workLog.log(.always)
//        }
//        XCTAssert(worker.taskCount == 0, "Worker should not recieve tasks before completing promise. Recieved: \(worker.taskCount)")
//
//        promise = nil
//        XCTAssert(worker.taskCount == 1, "Worker should recieve exactly one task when completing promise. Recieved: \(worker.taskCount)")
//        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
//
//        worker.executeFirst()
//        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
//        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
}

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
    
    func testShouldHandleValue_WhenCompletingWithValue_UsingThrowingRecovery() {
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.recover], "Work log not matching expected. Expected: \(WorkLog(.recover)) Recieved: \(workLog)")
        
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.catch], "Work log not matching expected. Expected: \(WorkLog(.catch)) Recieved: \(workLog)")
        
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.map], "Work log not matching expected. Expected: \(WorkLog(.map)) Recieved: \(workLog)")
        
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleValue_WhenCompletingWithValue_Using_FlatMapWithSuccess() {
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithValue_UsingThrowingFlatMapWith_Success() {
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [.flatMap], "Work log not matching expected. Expected: \(WorkLog(.flatMap)) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShouldHandleError_WhenCompletingWithError_UsingFlatMapWithSuccess() {
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
        XCTAssert(worker.taskCount == 1, "Worker should recieve task after completing promise with transforming handler. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == [], "Work log not matching expected. Expected: \(WorkLog()) Recieved: \(workLog)")
        
        worker.executeFirst()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
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
        
        XCTAssert(worker.taskCount == 4, "Worker task count not matching expected. Expected: \(4) Recieved: \(worker.taskCount)")
        
        worker.executeAll()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShould_HandleError_When_AlreadyCompleted_With_Error() {
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
        
        XCTAssert(worker.taskCount == 4, "Worker task count not matching expected. Expected: \(4) Recieved: \(worker.taskCount)")
        
        worker.executeAll()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShould_HandleCancel_When_AlreadyCanceled() {
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
        
        XCTAssert(worker.taskCount == 4, "Worker task count not matching expected. Expected: \(4) Recieved: \(worker.taskCount)")
        
        worker.executeAll()
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShould_CompleteOnce_When_AlreadySucceeded() {
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
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(0) Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        promise.break(with: TestError())
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShould_CompleteOnce_When_AlreadyFailed() {
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
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(0) Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        promise.break(with: TestError())
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }
    
    func testShould_CompleteOnce_When_AlreadyCanceled() {
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
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(0) Recieved: \(worker.taskCount)")
        
        promise.fulfill(with: 0)
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        promise.break(with: TestError())
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        promise.cancel()
        XCTAssert(worker.taskCount == 0, "Worker task count not matching expected. Expected: \(1) Recieved: \(worker.taskCount)")
        
        XCTAssert(worker.taskCount == 0, "Worker should not contain unused work after test. Recieved: \(worker.taskCount)")
        XCTAssert(workLog == expectedWorkLog, "Final work log not matching expected. Expected: \(expectedWorkLog) Recieved: \(workLog)")
    }

    
    
    /////////////////////////////////////// OLD /////////////////////////////////////////
    
    
    func testEmptyPromiseLongChainSuccess() {
        let expectedResult: String = "4"
        let promise: Promise<Int> = .init()
        
        var called: Bool = false
        
        promise.future
            .map {
                $0 + 2
            }
            .flatMap {
                .init(succeededWith: $0 * $0)
            }
            .map {
                String($0)
            }
            .recover { _ in
                return expectedResult
            }
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
        }
        
        promise.fulfill(with: 0)
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testEmptyPromiseLongChainFailure() {
        let expectedResult: TestError = .init()
        let promise: Promise<Int> = .init()
        
        var called: Bool = false
        
        promise.future
            .map {
                $0 + 2
            }
            .flatMap {
                .init(succeededWith: $0 * $0)
            }
            .map {
                String($0)
            }
            .recover {
                throw $0
            }
            .fail {
                called = true
                XCTAssert($0 is TestError, "Promise result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
        }
        
        promise.break(with: expectedResult)
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testEmptyPromiseLongChainCancel() {
        let promise: Promise<Int> = .init()
        
        var called: Bool = false
        
        promise.future
            .map {
                $0 + 2
            }
            .flatMap {
                .init(succeededWith: $0 * $0)
            }
            .map {
                String($0)
            }
            .recover {
                throw $0
            }
            .then { _ in
                XCTFail("Should not be called")
            }
            .fail { _ in
                XCTFail("Should not be called")
            }
            .always {
                called = true
        }
        
        promise.cancel()
        
        XCTAssert(called, "No handlers were called")
    }
 
    
    func testFutureFlatMap() {
        let expectedResult: Int = 1
        let future: Future<Int> = .init(succeededWith: 0)
        
        var called: Bool = false
        
        future
            .flatMap {
                .init(succeededWith: $0 + 1)
            }
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureThrowingFlatMap() {
        let expectedResult: TestError = .init()
        let future: Future<Int> = .init(succeededWith: 0)
        
        var called: Bool = false
        
        future
            .flatMap { (_) throws -> Future<Void> in
                throw expectedResult
            }
            .fail {
                called = true
                XCTAssert($0 is TestError, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureFlatMapCancel() {
        let future: Future<Int> = Promise<Int>().future
        future.cancel()
        
        var called: Bool = false
        
        future
            .flatMap {
                .init(succeededWith: $0 + 1)
            }
            .then { _ in
                XCTFail("Should not be called")
            }
            .always {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureFlatMapInnerCancel() {
        let future: Future<Int> = .init(succeededWith: 0)
        
        var called: Bool = false
        
        future
            .flatMap { _ -> Future<Int> in
                let inner: Future<Int> = Promise<Int>().future
                inner.cancel()
                return inner
            }
            .then { _ in
                XCTFail("Should not be called")
            }
            .always {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    
    func testFutureExecutionContextSwitch() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future: Future<Int> = .init(succeededWith: 0)
            
            let onMarked = future
                .always {
                    XCTAssert(!DispatchQueue.isOnMarkedQueue, "Execution on incorrect DispatchQueue")
                }
                .switch(to: DispatchWorker.custom(markedQueue))
            DispatchWorker.default.schedule {
                let mapped = onMarked
                    .always {
                        XCTAssert(DispatchQueue.isOnMarkedQueue, "Execution on incorrect DispatchQueue")
                    }
                    .map { $0 }
                DispatchWorker.default.schedule {
                    mapped
                        .always {
                            XCTAssert(DispatchQueue.isOnMarkedQueue, "Execution on incorrect DispatchQueue")
                            complete()
                        }
                }
            }
        }
    }
    
    func testFutureCloning() {
        let expectedResult = 0
        let promise: Promise<Int> = .init()
        let futureToCancel = promise.future.clone().then { _ in
            XCTFail("Should not be called")
        }
        promise.future.clone().then {
            XCTAssert($0 == expectedResult, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
        }
        promise.future.clone().then {
            XCTAssert($0 == expectedResult, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
        }
        
        futureToCancel.cancel()
        promise.fulfill(with: expectedResult)
    }
    
    func testFutureRecursiveHandlerOnCompleted() {
        let future: Future<Int> = .init(succeededWith: 0)
        
        future.always {
            future.always {
                future.always {
                    future.always {
                        return Void()
                    }
                }
            }
        }
    }
    
    func testFutureRecursiveHandlerOnWaiting() {
        let future: Future<Int> = Promise<Int>().future
        
        future.always {
            future.always {
                future.always {
                    future.always {
                        return Void()
                    }
                }
            }
        }
    }
    
    func testFutureExecutionContextSwitchOnCancel() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future: Future<Int> = Promise<Int>().future
            future.cancel()
            
            future
                .switch(to: DispatchWorker.custom(markedQueue))
                .always {
                    XCTAssert(DispatchQueue.isOnMarkedQueue, "Execution on incorrect DispatchQueue")
                    complete()
                }
        }
    }
    
    func testFutureLongChainSuccess() {
        let expectedResult: String = "4"
        let future: Future<Int> = .init(succeededWith: 0)
        
        var called: Bool = false
        
        future
            .map {
                $0 + 2
            }
            .flatMap {
                .init(succeededWith: $0 * $0)
            }
            .map {
                String($0)
            }
            .recover { _ in
                return expectedResult
            }
            .catch {
                throw $0
            }
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureLongChainFailure() {
        let expectedResult: TestError = .init()
        let future: Future<Int> = .init(failedWith: expectedResult)
        
        var called: Bool = false
        
        future
            .map {
                $0 + 2
            }
            .flatMap {
                .init(succeededWith: $0 * $0)
            }
            .map {
                String($0)
            }
            .recover {
                throw $0
            }
            .catch {
                throw $0
            }
            .fail {
                called = true
                XCTAssert($0 is TestError, "Promise result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureLongChainCancel() {
        let future: Future<Int> = Promise<Int>().future
        future.cancel()
        
        var called: Bool = false
        
        future
            .map {
                $0 + 2
            }
            .flatMap {
                .init(succeededWith: $0 * $0)
            }
            .map {
                String($0)
            }
            .recover {
                throw $0
            }
            .catch {
                throw $0
            }
            .always {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureDealocationOnPromiseDealocation() {
        var promise: Promise<Int>? = Promise<Int>(succeededWith: 0)
        weak var future = promise?.future
        XCTAssert(future != nil, "Future deallocated while responsible Promise still available")
        promise = nil
        XCTAssert(future == nil, "Future not deallocated while responsible Promise dealocated")
    }
    
    func testFutureCancelationOnDealocation() {
        var future_1: Future<Int>? = Promise<Int>().future
        let future_2 = future_1!.map { $0 }
        
        var called: Bool = false
        future_2.always {
            called = true
        }
        
        XCTAssert(future_1 != nil, "Future_1 deallocated while responsible Promise still available")
        XCTAssert(!called, "Handlers were called to early")
        
        future_1 = nil
        
        XCTAssert(future_1 == nil, "Future_1 not deallocated while responsible Promise dealocated")
        XCTAssert(called, "No handlers were called")
    }
    
    func testCompletedFutureLongChainDealocationOnPromiseDealocation() {
        var promise: Promise<Int>? = .init(succeededWith: 0)
        weak var future_0 = promise?.future
        weak var future_1 = future_0?.map {
            $0 + 2
        }
        weak var future_2 = future_1?
            .flatMap {
                .init(succeededWith: $0 * $0)
        }
        weak var future_3 = future_2?
            .map {
                return String($0)
        }
        weak var future_4 = future_3?
            .recover { _ in
                return "0"
            }
        
        XCTAssert(future_0 != nil, "Future (0) deallocated while responsible Promise still available")
        XCTAssert(future_1 == nil, "Future (1) not deallocated while parent Future completed")
        XCTAssert(future_2 == nil, "Future (2) not deallocated while parent Future completed")
        XCTAssert(future_3 == nil, "Future (3) not deallocated while parent Future completed")
        XCTAssert(future_4 == nil, "Future (4) not deallocated while parent Future completed")
        
        promise = nil
        
        XCTAssert(future_0 == nil, "Future (0) not deallocated while responsible Promise dealocated")
    }
    
    func testWaitingFutureLongChainDealocationOnPromiseDealocation() {
        var promise: Promise<Int>? = .init()
        weak var future_0 = promise?.future
        weak var future_1 = future_0?.map {
            $0 + 2
        }
        weak var future_2 = future_1?
            .flatMap {
                .init(succeededWith: $0 * $0)
        }
        weak var future_3 = future_2?
            .map {
                return String($0)
        }
        weak var future_4 = future_3?
            .recover { _ in
                return "0"
        }
        
        XCTAssert(future_0 != nil, "Future (0) deallocated while responsible Promise still available")
        XCTAssert(future_1 != nil, "Future (1) deallocated while parent Future not completed and responsible Promise still available")
        XCTAssert(future_2 != nil, "Future (2) deallocated while parent Future not completed and responsible Promise still available")
        XCTAssert(future_3 != nil, "Future (3) deallocated while parent Future not completed and responsible Promise still available")
        XCTAssert(future_4 != nil, "Future (4) deallocated while parent Future not completed and responsible Promise still available")
        
        promise = nil
        
        XCTAssert(future_0 == nil, "Future (0) not deallocated while responsible Promise dealocated and MemoryKeeper release")
        XCTAssert(future_1 == nil, "Future (1) not deallocated while responsible Promise dealocated and MemoryKeeper release")
        XCTAssert(future_2 == nil, "Future (2) not deallocated while responsible Promise dealocated and MemoryKeeper release")
        XCTAssert(future_3 == nil, "Future (3) not deallocated while responsible Promise dealocated and MemoryKeeper release")
        XCTAssert(future_4 == nil, "Future (4) not deallocated while responsible Promise dealocated and MemoryKeeper release")
    }
}

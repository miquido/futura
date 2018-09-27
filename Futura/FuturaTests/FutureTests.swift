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
@testable import Futura

class FutureTests: XCTestCase {

    func testFutureThen() {
        let expectedResult: Int = 0
        let future: Future<Int> = .init(with: .success(expectedResult))
        
        var called: Bool = false
        
        future
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
            .fail { _ in
                XCTFail("Should not be called")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureThenIgnoreOnFailure() {
        let future: Future<Int> = .init(with: .error(TestError()))
        
        future
            .then { _ in
                XCTFail("Should not be called")
            }
    }
    
    func testFutureThenIgnoreOnCancel() {
        let future: Future<Int> = .init()
        future.cancel()
        
        future
            .then { _ in
                XCTFail("Should not be called")
            }
    }
    
    func testFutureError() {
        let expectedResult: TestError = .init()
        let future: Future<Int> = .init(with: .error(expectedResult))
        
        var called: Bool = false
        
        future
            .fail {
                called = true
                XCTAssert($0 is TestError, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
            .then { _ in
                XCTFail("Should not be called")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureErrorIgnoreOnSuccess() {
        let future: Future<Int> = .init(with: .success(0))
        
        future
            .fail { _ in
                XCTFail("Should not be called")
            }
    }
    
    func testFutureErrorIgnoreOnCancel() {
        let future: Future<Int> = .init()
        future.cancel()
        
        future
            .fail { _ in
                XCTFail("Should not be called")
            }
    }
    
    func testFutureCanceled() {
        let future: Future<Int> = .init()
        future.cancel()
        
        var called: Bool = false
        
        future
            .always {
                called = true
            }
            .then { _ in
                XCTFail("Should not be called")
            }
            .fail { _ in
                XCTFail("Should not be called")
            }
        
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureResulted() {
        let futureSuccess: Future<Int> = .init(with: .success(0))
        let futureError: Future<Int> = .init(with: .error(TestError()))
        let futureCancel: Future<Int> = .init()
        futureCancel.cancel()
        
        var called: Bool = false
        
        futureSuccess
            .resulted {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
        
        called = false
        
        futureError
            .resulted {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
        
        futureCancel
            .resulted {
                XCTFail("Should not be called")
            }
    }
    
    func testFutureAlways() {
        let futureSuccess: Future<Int> = .init(with: .success(0))
        let futureError: Future<Int> = .init(with: .error(TestError()))
        let futureCancel: Future<Int> = .init()
        futureCancel.cancel()
        
        var called: Bool = false
        futureSuccess
            .always {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
        
        called = false
        futureError
            .always {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
        
        called = false
        futureCancel
            .always {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureCatch() {
        let future: Future<Int> = .init(with: .error(TestError()))
        
        var called: Bool = false
        
        let futureCatched = future.catch { _ in called = true }
        let futureNotCatched = future.catch { error in called = true ; throw error }
        
        futureCatched
            .fail { _ in
                XCTFail("Should not be called")
            }
            .always {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
        
        called = false
        
        futureNotCatched
            .fail { _ in
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureMap() {
        let expectedResult: Int = 1
        let future: Future<Int> = .init(with: .success(0))
        
        var called: Bool = false
        
        future
            .map {
                $0 + 1
            }
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureThrowingMap() {
        let expectedResult: TestError = .init()
        let future: Future<Int> = .init(with: .success(0))
        
        var called: Bool = false
        
        future
            .map { (_) -> Void in
                throw expectedResult
            }
            .fail {
                called = true
                XCTAssert($0 is TestError, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureFlatMap() {
        let expectedResult: Int = 1
        let future: Future<Int> = .init(with: .success(0))
        
        var called: Bool = false
        
        future
            .flatMap {
                .init(with: .success($0 + 1))
            }
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureThrowingFlatMap() {
        let expectedResult: TestError = .init()
        let future: Future<Int> = .init(with: .success(0))
        
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
    
    func testFutureRecoverSuccess() {
        let expectedResult: Int = 0
        let future: Future<Int> = .init(with: .error(TestError()))
        
        var called: Bool = false
        
        future
            .recover { _ in
                return expectedResult
            }
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Future result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureRecoverFailure() {
        let expectedResult: TestError = .init()
        let future: Future<Int> = .init(with: .error(expectedResult))
        
        var called: Bool = false
        
        future
            .recover {
                throw $0
            }
            .fail {
                called = true
                XCTAssert($0 is TestError, "Promise result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFutureExecutionContextSwitch() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future: Future<Int> = .init(with: .success(0))
            
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
        let future: Future<Int> = .init(with: .success(0))
        
        var called: Bool = false
        
        future
            .map {
                $0 + 2
            }
            .flatMap {
                .init(with: .success($0 * $0))
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
        let future: Future<Int> = .init(with: .error(expectedResult))
        
        var called: Bool = false
        
        future
            .map {
                $0 + 2
            }
            .flatMap {
                .init(with: .success($0 * $0))
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
        let future: Future<Int> = .init()
        future.cancel()
        
        var called: Bool = false
        
        future
            .map {
                $0 + 2
            }
            .flatMap {
                .init(with: .success($0 * $0))
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
        var promise: Promise<Int>? = .init(with: .success(0))
        weak var future = promise?.future
        XCTAssert(future != nil, "Future deallocated while responsible Promise still available")
        promise = nil
        XCTAssert(future == nil, "Future not deallocated while responsible Promise dealocated")
    }
    
    func testFutureCancelationOnDealocation() {
        var future_1: Future<Int>? = .init()
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
        var promise: Promise<Int>? = .init(with: .success(0))
        weak var future_0 = promise?.future
        weak var future_1 = future_0?.map {
            $0 + 2
        }
        weak var future_2 = future_1?
            .flatMap {
                .init(with: .success($0 * $0))
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
                .init(with: .success($0 * $0))
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

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

class PromiseTest: XCTestCase {
    
    func testEmptyPromiseCompleteWithSuccess() {
        let expectedResult: Int = 0
        let promise: Promise<Int> = .init()
        
        var called: Bool = false
        
        promise.future
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Promise result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
            .fail { _ in
                XCTFail("Should not be called")
            }
        
        promise.fulfill(with: expectedResult)
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testEmptyPromiseCompleteWithError() {
        let expectedResult: TestError = .init()
        let promise: Promise<Int> = .init()
        
        var called: Bool = false
        
        promise.future
            .fail {
                called = true
                XCTAssert($0 is TestError, "Promise result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
            .then { _ in
                XCTFail("Should not be called")
            }
        
        promise.break(with: expectedResult)
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testEmptyPromiseCancel() {
        let promise: Promise<Int> = .init()
        
        var called: Bool = false
        
        promise.future
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
    
    func testSuccededPromise() {
        let expectedResult: Int = 0
        let promise: Promise<Int> = .init(succeededWith: expectedResult)
        
        var called: Bool = false
        
        promise.future
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Promise result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
            .fail { _ in
                XCTFail("Should not be called")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testFailedPromise() {
        let expectedResult: TestError = .init()
        let promise: Promise<Int> = .init(failedWith: expectedResult)
        
        var called: Bool = false
        
        promise.future
            .fail {
                called = true
                XCTAssert($0 is TestError, "Promise result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
            .then { _ in
                XCTFail("Should not be called")
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testCanceledPromise() {
        let promise: Promise<Int> = .init()
        promise.cancel()
        
        var called: Bool = false
        
        promise.future
            .then { _ in
                XCTFail("Should not be called")
            }
            .fail { _ in
                XCTFail("Should not be called")
            }
            .always {
                called = true
            }
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testEmptyPromiseMultipleCompleteSuccess() {
        let expectedResult: Int = 0
        let promise: Promise<Int> = .init()
        
        var called: Bool = false
        
        promise.future
            .then {
                called = true
                XCTAssert($0 == expectedResult, "Promise result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
            .fail { _ in
                XCTFail("Should not be called")
            }
        
        promise.fulfill(with: expectedResult)
        promise.break(with: TestError())
        promise.cancel()
        promise.fulfill(with: 1)
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testEmptyPromiseMultipleCompleteFailure() {
        let expectedResult: TestError = .init()
        let promise: Promise<Int> = .init()
        
        var called: Bool = false
        
        promise.future
            .fail {
                called = true
                XCTAssert($0 is TestError, "Promise result not matching expected. Expected: \(expectedResult) Recieved: \($0)")
            }
            .then { _ in
                XCTFail("Should not be called")
            }
        
        promise.break(with: expectedResult)
        promise.fulfill(with: 0)
        promise.cancel()
        promise.break(with: NSError(domain: "TEST", code: 0, userInfo: nil))
        
        XCTAssert(called, "No handlers were called")
    }
    
    func testEmptyPromiseMultipleCompleteCancel() {
        let promise: Promise<Int> = .init()
        
        var called: Bool = false
        
        promise.future
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
        promise.break(with: TestError())
        promise.fulfill(with: 0)
        promise.cancel()
        
        XCTAssert(called, "No handlers were called")
    }
}

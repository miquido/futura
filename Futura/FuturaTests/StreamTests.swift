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

class StreamTests: XCTestCase {
    
    var channel: Channel<Int>! = .init()

    override func setUp() {
        super.setUp()
        channel = .init()
    }
    
    func testShouldHandleValue_WhenBroadcastingValue() {
        var called: Bool = false
        channel
            .next {
                called = true
                XCTAssertEqual($0, 0)
            }
            .fail { _ in
                XCTFail()
            }
        channel.broadcast(0)
        XCTAssert(called)
    }
    
    func testShouldHandleError_WhenBroadcastingError() {
        var called: Bool = false
        channel
            .next { _ in
                XCTFail()
            }
            .fail {
                called = true
                XCTAssert($0 is TestError)
            }
        channel.broadcast(testError)
        XCTAssert(called)
    }
    
    func testShouldHandleClose_WhenClosing() {
        var called: Bool = false
        channel
            .next { _ in
                XCTFail()
            }
            .fail { _ in
                XCTFail()
            }
            .closed {
                called = true
            }
        
        channel.close()
        XCTAssert(called)
    }
    
    func testShouldHandleClose_WhenDeallocating() {
        var called: Bool = false
        channel
            .next { _ in
                XCTFail()
            }
            .fail { _ in
                XCTFail()
            }
            .closed {
                called = true
            }

        channel = nil
        XCTAssert(called)
    }
    
    func testShouldHandleTermination_WhenTerminating() {
        var called: Bool = false
        channel
            .next { _ in
                XCTFail()
            }
            .fail { _ in
                XCTFail()
            }
            .closed {
                XCTFail()
            }
            .terminated {
                called = true
                XCTAssert($0 is TestError)
            }
        
        channel.terminate(testError)
        XCTAssert(called)
    }
    
    func testShouldNotHandle_AfterClosing() {
        channel
            .next { _ in
                XCTFail()
            }
            .fail { _ in
                XCTFail()
            }
        channel.close()
        channel.broadcast(0)
        channel.broadcast(testError)
    }
    
    func testShouldHandleValue_WhenBroadcastingValue_WithTransformations() {
        var called: Bool = false
        channel
            .map { $0 }
            .next {
                called = true
                XCTAssertEqual($0, 0)
            }
            .fail { _ in
                XCTFail()
        }
        channel.broadcast(0)
        XCTAssert(called)
    }
    
    func testShouldHandleError_WhenBroadcastingError_WithTransformations() {
        var called: Bool = false
        channel
            .map { $0 }
            .next { _ in
                XCTFail()
            }
            .fail {
                called = true
                XCTAssert($0 is TestError)
        }
        channel.broadcast(testError)
        XCTAssert(called)
    }
    
    func testShouldHandleClose_WhenClosing_WithTransformations() {
        var called: Bool = false
        channel
            .map { $0 }
            .next { _ in
                XCTFail()
            }
            .fail { _ in
                XCTFail()
            }
            .closed {
                called = true
        }
        
        channel.close()
        XCTAssert(called)
    }
    
    func testShouldNotHandle_WhenAlreadyClosed() {
        var called: Int = 0
        
        channel
            .next { _ in
                called += 1
            }
            .fail { _ in
                called += 1
            }
            .closed {
                called += 1
        }
        
        channel.broadcast(0)
        channel.broadcast(testError)
        channel.close()
        channel.broadcast(0)
        channel.broadcast(testError)
        XCTAssertEqual(called, 3)
    }
    
    func testShouldNotHandle_WhenDeallocatedCollector() {
        var collector: SubscribtionCollector! = .init()
        var called: Int = 0
        
        channel
            .collect(with: collector)
            .next { _ in
                called += 1
            }
            .fail { _ in
                called += 1
            }
            .closed {
                called += 1
            }
        
        channel.broadcast(0)
        channel.broadcast(testError)
        collector = nil
        channel.broadcast(0)
        channel.broadcast(testError)
        channel.close()
        XCTAssertEqual(called, 2)
    }
}

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
    
    var workLog: StreamWorkLog = .init()
    var channel: Channel<Int>! = .init()
    
    override func setUp() {
        super.setUp()
        workLog = .init()
        channel = .init()
    }
    
    // MARK: -
    // MARK: Access
    
    func testShouldHandleValue_WhenBroadcastingValue() {
        channel.stream
            .next {
                self.workLog.log(.next(testDescription(of: $0)))
            }
            .fail {
                self.workLog.log(.fail(testDescription(of: $0)))
            }
            .closed {
                self.workLog.log(.closed)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
        }
        
        channel.broadcast(0)
        XCTAssertEqual(workLog, [.next(testDescription(of: 0))])
    }
    
    func testShouldHandleError_WhenBroadcastingError() {
        channel.stream
            .next {
                self.workLog.log(.next(testDescription(of: $0)))
            }
            .fail {
                self.workLog.log(.fail(testDescription(of: $0)))
            }
            .closed {
                self.workLog.log(.closed)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
        }
        
        channel.broadcast(testError)
        XCTAssertEqual(workLog, [.fail(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenClosing() {
        channel.stream
            .next {
                self.workLog.log(.next(testDescription(of: $0)))
            }
            .fail {
                self.workLog.log(.fail(testDescription(of: $0)))
            }
            .closed {
                self.workLog.log(.closed)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
        }
        
        channel.close()
        XCTAssertEqual(workLog, [.closed])
    }
    
    func testShouldHandleTermination_WhenTerminating() {
        channel.stream
            .next {
                self.workLog.log(.next(testDescription(of: $0)))
            }
            .fail {
                self.workLog.log(.fail(testDescription(of: $0)))
            }
            .closed {
                self.workLog.log(.closed)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
        }
        
        channel.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenDeallocating() {
        channel.stream
            .next {
                self.workLog.log(.next(testDescription(of: $0)))
            }
            .fail {
                self.workLog.log(.fail(testDescription(of: $0)))
            }
            .closed {
                self.workLog.log(.closed)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
        }
        
        channel = nil
        XCTAssertEqual(workLog, [.closed])
    }
    
    func testShouldNotHandle_AfterClosing() {
        channel.stream
            .next {
                self.workLog.log(.next(testDescription(of: $0)))
            }
            .fail {
                self.workLog.log(.fail(testDescription(of: $0)))
            }
            .closed {
                self.workLog.log(.closed)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
        }
        
        channel.close()
        channel.broadcast(0)
        channel.broadcast(testError)
        channel.close()
        channel.terminate(testError)
        XCTAssertEqual(workLog, [.closed])
    }
    
    func testShouldNotHandle_AfterTerminating() {
        channel.stream
            .next {
                self.workLog.log(.next(testDescription(of: $0)))
            }
            .fail {
                self.workLog.log(.fail(testDescription(of: $0)))
            }
            .closed {
                self.workLog.log(.closed)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
        }
        
        channel.terminate(testError)
        channel.broadcast(0)
        channel.broadcast(testError)
        channel.close()
        channel.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription)])
    }
    
    // MARK: -
    // MARK: Map
    
    func testShouldHandleValue_WhenBroadcastingValue_WithMap() {
        channel
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)
        
        channel.broadcast(0)
        XCTAssertEqual(workLog, [.map, .next(testDescription(of: 0))])
    }
    
    func testShouldHandleError_WhenBroadcastingError_WithMap() {
        channel
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)
        
        channel.broadcast(testError)
        XCTAssertEqual(workLog, [.fail(testErrorDescription)])
    }
    
    func testShouldHandleError_WhenBroadcastingValue_WithThrowingMap() {
        channel
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                throw testError
            }
            .logResults(with: workLog)
        
        channel.broadcast(0)
        XCTAssertEqual(workLog, [.map, .fail(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenClosing_WithMap() {
        channel
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)
        
        
        channel.close()
        XCTAssertEqual(workLog, [.closed])
    }
    
    func testShouldHandleTerminate_WhenTerminating_WithMap() {
        channel
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)
        
        channel.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenDeallocating_WithMap() {
        channel
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)
        
        
        channel = nil
        XCTAssertEqual(workLog, [.closed])
    }
    
    // MARK: -
    // MARK: FlatMap
    
    func testShouldHandleValue_WhenBroadcastingValue_WithFlatMap_WithValue() {
        let otherChannel = Channel<Int>()
        
        channel
            .flatMap({ (val: Int) -> Futura.Stream<Int> in
                self.workLog.log(.flatMap)
                return otherChannel
            })
            .logResults(with: workLog)
        
        otherChannel.broadcast(2)
        channel.broadcast(0)
        otherChannel.broadcast(1)
        XCTAssertEqual(workLog, [.flatMap, .next(testDescription(of: 1))])
    }
    
    func testShouldHandleError_WhenBroadcastingValue_WithFlatMap_WithError() {
        let otherChannel = Channel<Int>()
        
        channel
            .flatMap({ (val: Int) -> Futura.Stream<Int> in
                self.workLog.log(.flatMap)
                return otherChannel
            })
            .logResults(with: workLog)
        
        otherChannel.broadcast(testError)
        channel.broadcast(0)
        otherChannel.broadcast(testError)
        XCTAssertEqual(workLog, [.flatMap, .fail(testErrorDescription)])
    }
    
    func testShouldHandleClosed_WhenBroadcastingValue_WithFlatMap_WithClose() {
        let otherChannel = Channel<Int>()
        
        channel
            .flatMap({ (val: Int) -> Futura.Stream<Int> in
                self.workLog.log(.flatMap)
                return otherChannel
            })
            .logResults(with: workLog)
        
        channel.broadcast(0)
        otherChannel.close()
        channel.broadcast(0)
        otherChannel.broadcast(0)
        XCTAssertEqual(workLog, [.flatMap, .closed, .flatMap])
    }
    
    func testShouldHandleTerminated_WhenBroadcastingValue_WithFlatMap_WithTerminate() {
        let otherChannel = Channel<Int>()
        
        channel
            .flatMap({ (val: Int) -> Futura.Stream<Int> in
                self.workLog.log(.flatMap)
                return otherChannel
            })
            .logResults(with: workLog)
        
        channel.broadcast(0)
        otherChannel.terminate(testError)
        channel.broadcast(0)
        otherChannel.broadcast(0)
        XCTAssertEqual(workLog, [.flatMap, .terminated(testErrorDescription), .flatMap])
    }
    
    func testShouldHandleError_WhenBroadcastingError_WithFlatMap() {
        let otherChannel = Channel<Int>()
        
        channel
            .flatMap({ (val: Int) -> Futura.Stream<Int> in
                self.workLog.log(.flatMap)
                return otherChannel
            })
            .logResults(with: workLog)
        
        otherChannel.broadcast(2)
        channel.broadcast(testError)
        otherChannel.broadcast(1)
        XCTAssertEqual(workLog, [.fail(testErrorDescription)])
    }
    
    func testShouldHandleError_WhenBroadcastingValue_WithThrowingFlatMap() {
        let otherChannel = Channel<Int>()
        
        channel
            .flatMap({ (val: Int) -> Futura.Stream<Int> in
                self.workLog.log(.flatMap)
                throw testError
            })
            .logResults(with: workLog)
        
        otherChannel.broadcast(2)
        channel.broadcast(0)
        otherChannel.broadcast(1)
        XCTAssertEqual(workLog, [.flatMap, .fail(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenClosing_WithFlatMap() {
        let otherChannel = Channel<Int>()
        
        channel
            .flatMap({ (val: Int) -> Futura.Stream<Int> in
                self.workLog.log(.flatMap)
                return otherChannel
            })
            .logResults(with: workLog)
        
        otherChannel.broadcast(2)
        channel.close()
        otherChannel.broadcast(1)
        XCTAssertEqual(workLog, [.closed])
    }
    
    func testShouldHandleTerminate_WhenTerminating_WithFlatMap() {
        let otherChannel = Channel<Int>()
        
        channel
            .flatMap({ (val: Int) -> Futura.Stream<Int> in
                self.workLog.log(.flatMap)
                return otherChannel
            })
            .logResults(with: workLog)
        
        otherChannel.broadcast(2)
        channel.terminate(testError)
        otherChannel.broadcast(1)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenDeallocating_WithFlatMap() {
        let otherChannel = Channel<Int>()
        
        channel
            .flatMap({ (val: Int) -> Futura.Stream<Int> in
                self.workLog.log(.flatMap)
                return otherChannel
            })
            .logResults(with: workLog)
        
        otherChannel.broadcast(2)
        channel = nil
        otherChannel.broadcast(1)
        XCTAssertEqual(workLog, [.closed])
    }
    
    // MARK: -
    // MARK: Collector
    
    func testShouldHandleValue_WhenBroadcastingValue_WithCollector() {
        var collector: SubscribtionCollector! = .init()
        
        channel
            .collect(with: collector)
            .logResults(with: workLog)
        
        channel.broadcast(0)
        collector = nil
        channel.broadcast(0)
        XCTAssertEqual(workLog, [.next(testDescription(of: 0))])
    }
    
    func testShouldHandleError_WhenBroadcastingError_WithCollector() {
        var collector: SubscribtionCollector! = .init()
        
        channel
            .collect(with: collector)
            .logResults(with: workLog)
        
        channel.broadcast(testError)
        collector = nil
        channel.broadcast(testError)
        XCTAssertEqual(workLog, [.fail(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenClosing_WithCollector() {
        var collector: SubscribtionCollector! = .init()
        
        channel
            .collect(with: collector)
            .logResults(with: workLog)
        
        
        channel.close()
        collector = nil
        XCTAssertEqual(workLog, [.closed])
    }
    
    func testShouldHandleTerminate_WhenTerminating_WithCollector() {
        let collector: SubscribtionCollector! = .init()
        
        channel
            .collect(with: collector)
            .logResults(with: workLog)
        
        channel.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenDeallocating_WithCollector() {
        let collector: SubscribtionCollector! = .init()
        
        channel
            .collect(with: collector)
            .logResults(with: workLog)
        
        
        channel = nil
        XCTAssertEqual(workLog, [.closed])
    }
    
    func testShouldNotHandle_WhenClosing_WithCollector() {
        var collector: SubscribtionCollector! = .init()
        
        channel
            .collect(with: collector)
            .logResults(with: workLog)
        
        collector = nil
        channel.close()
        XCTAssertEqual(workLog, [])
    }
    
    func testShouldNotHandle_WhenTerminating_WithCollector() {
        var collector: SubscribtionCollector! = .init()
        
        channel
            .collect(with: collector)
            .logResults(with: workLog)
        
        collector = nil
        channel.terminate(testError)
        XCTAssertEqual(workLog, [])
    }
    
    func testShouldNotHandle_WhenDeallocating_WithCollector() {
        var collector: SubscribtionCollector! = .init()
        
        channel
            .collect(with: collector)
            .logResults(with: workLog)
        
        collector = nil
        channel = nil
        XCTAssertEqual(workLog, [])
    }
    
    // MARK: -
    // MARK: WorkerSwitch
    
    func testShouldHandleValue_WhenBroadcastingValue_WithWorkerSwitch() {
        let worker: TestWorker = .init()
        
        channel
            .switch(to: worker)
            .logResults(with: workLog)
        
        channel.broadcast(0)
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.next(testDescription(of: 0))])
    }
    
    func testShouldHandleError_WhenBroadcastingError_WithWorkerSwitch() {
        let worker: TestWorker = .init()
        
        channel
            .switch(to: worker)
            .logResults(with: workLog)
        
        channel.broadcast(testError)
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.fail(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenClosing_WithWorkerSwitch() {
        let worker: TestWorker = .init()
        
        channel
            .switch(to: worker)
            .logResults(with: workLog)
        
        channel.close()
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.closed])
    }
    
    func testShouldHandleTerminate_WhenTerminating_WithWorkerSwitch() {
        let worker: TestWorker = .init()
        
        channel
            .switch(to: worker)
            .logResults(with: workLog)
        
        channel.terminate(testError)
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.terminated(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenDeallocating_WithWorkerSwitch() {
        let worker: TestWorker = .init()
        
        channel
            .switch(to: worker)
            .logResults(with: workLog)
        
        
        channel = nil
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.closed])
    }
    
    // MARK: -
    // MARK: Filter
    
    func testShouldHandleValue_WhenBroadcastingValue_WithFilterPassing() {
        channel
            .filter {
                let result = $0 == 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)
        
        channel.broadcast(0)
        XCTAssertEqual(workLog, [.filter(true), .next(testDescription(of: 0))])
    }
    
    func testShouldNotHandle_WhenBroadcastingValue_WithFilterNotPassing() {
        channel
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)
        
        channel.broadcast(0)
        XCTAssertEqual(workLog, [.filter(false)])
    }
    
    func testShouldHandleError_WhenBroadcastingError_WithFilter() {
        channel
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)
        
        channel.broadcast(testError)
        XCTAssertEqual(workLog, [.fail(testErrorDescription)])
    }
    
    
    func testShouldHandleClose_WhenClosing_WithFilter() {
        channel
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)
        
        
        channel.close()
        XCTAssertEqual(workLog, [.closed])
    }
    
    func testShouldHandleTerminate_WhenTerminating_WithFilter() {
        channel
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)
        
        channel.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription)])
    }
    
    func testShouldHandleClose_WhenDeallocating_WithFilter() {
        channel
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)
        
        
        channel = nil
        XCTAssertEqual(workLog, [.closed])
    }
    
    // MARK: -
    // MARK: thread safety
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenAccessingOnManyThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: RecursiveLock = .init()
            let lock_2: RecursiveLock = .init()
            let lock_3: RecursiveLock = .init()
            var counter_1 = 0
            var counter_2 = 0
            var counter_3 = 0
            
            dispatchQueue.async {
                lock_1.lock()
                for _ in 0..<100 {
                    self.channel.next { _ in counter_1 += 1 }
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                for _ in 0..<100 {
                    self.channel.next { _ in counter_2 += 1 }
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                for _ in 0..<100 {
                    self.channel.next { _ in counter_3 += 1 }
                }
                lock_3.unlock()
            }
            
            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            self.channel.broadcast(0)
            
            XCTAssertEqual(counter_1 + counter_2 + counter_3, 300, "Calls count not matching expected")
            complete()
        }
    }
}

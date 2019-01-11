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

class SignalTests: XCTestCase {
    var workLog: StreamWorkLog = .init()
    var emitter: Emitter<Int>! = .init()

    override func setUp() {
        super.setUp()
        workLog = .init()
        emitter = .init()
    }

    // MARK: -

    // MARK: access

    func testShouldHandleValue_WhenBroadcastingValue() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        emitter.emit(0)
        XCTAssertEqual(workLog, [.values(testDescription(of: 0)), .tokens])
    }

    func testShouldHandleError_WhenBroadcastingError() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        emitter.emit(testError)
        XCTAssertEqual(workLog, [.errors(testErrorDescription), .tokens])
    }

    func testShouldHandleEnd_WhenClosing() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        emitter.end()
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleTermination_WhenTerminating() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        emitter.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }

    func testShouldHandleEnd_WhenAlreadyEnded() {
        emitter.end()
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleTermination_WhenAlreadyTerminated() {
        emitter.terminate(testError)
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }

    func testShouldHandleEnd_WhenDeallocating() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        emitter = nil
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldNotHandle_AfterClosing() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        emitter.end()
        emitter.emit(0)
        emitter.emit(testError)
        emitter.end()
        emitter.terminate(testError)
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldNotHandle_AfterTerminating() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
            }
            .tokens {
                self.workLog.log(.tokens)
            }
            .ended {
                self.workLog.log(.ended)
            }
            .terminated {
                self.workLog.log(.terminated(testDescription(of: $0)))
            }
            .finished {
                self.workLog.log(.finished)
            }

        emitter.terminate(testError)
        emitter.emit(0)
        emitter.emit(testError)
        emitter.end()
        emitter.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }

    // MARK: -

    // MARK: map

    func testShouldHandleValue_WhenBroadcastingValue_WithMap() {
        emitter
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)

        emitter.emit(0)
        XCTAssertEqual(workLog, [.map, .values(testDescription(of: 0))])
    }

    func testShouldHandleError_WhenBroadcastingError_WithMap() {
        emitter
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)

        emitter.emit(testError)
        XCTAssertEqual(workLog, [.errors(testErrorDescription)])
    }

    func testShouldHandleError_WhenBroadcastingValue_WithThrowingMap() {
        emitter
            .map { (_: Int) -> Int in
                self.workLog.log(.map)
                throw testError
            }
            .logResults(with: workLog)

        emitter.emit(0)
        XCTAssertEqual(workLog, [.map, .errors(testErrorDescription)])
    }

    func testShouldHandleEnd_WhenClosing_WithMap() {
        emitter
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)

        emitter.end()
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleTerminate_WhenTerminating_WithMap() {
        emitter
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)

        emitter.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }

    func testShouldHandleEnd_WhenDeallocating_WithMap() {
        emitter
            .map { (val: Int) -> Int in
                self.workLog.log(.map)
                return val
            }
            .logResults(with: workLog)

        emitter = nil
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    // MARK: -

    // MARK: flatMap

    func testShouldHandleValue_WhenBroadcastingValue_WithFlatMap_WithValue() {
        let otherEmitter = Emitter<Int>()

        emitter
            .flatMap({ (_: Int) -> Futura.Signal<Int> in
                self.workLog.log(.flatMap)
                return otherEmitter
            })
            .logResults(with: workLog)

        otherEmitter.emit(2)
        emitter.emit(0)
        otherEmitter.emit(1)
        XCTAssertEqual(workLog, [.flatMap, .values(testDescription(of: 1))])
    }

    func testShouldHandleError_WhenBroadcastingValue_WithFlatMap_WithError() {
        let otherEmitter = Emitter<Int>()

        emitter
            .flatMap({ (_: Int) -> Futura.Signal<Int> in
                self.workLog.log(.flatMap)
                return otherEmitter
            })
            .logResults(with: workLog)

        otherEmitter.emit(testError)
        emitter.emit(0)
        otherEmitter.emit(testError)
        XCTAssertEqual(workLog, [.flatMap, .errors(testErrorDescription)])
    }

    func testShouldHandlEended_WhenBroadcastingValue_WithFlatMap_WithEnd() {
        let otherEmitter = Emitter<Int>()

        emitter
            .flatMap({ (_: Int) -> Futura.Signal<Int> in
                self.workLog.log(.flatMap)
                return otherEmitter
            })
            .logResults(with: workLog)

        emitter.emit(0)
        otherEmitter.end()
        emitter.emit(0)
        otherEmitter.emit(0)
        XCTAssertEqual(workLog, [.flatMap, .ended, .finished, .flatMap])
    }

    func testShouldHandleTerminated_WhenBroadcastingValue_WithFlatMap_WithTerminate() {
        let otherEmitter = Emitter<Int>()

        emitter
            .flatMap({ (_: Int) -> Futura.Signal<Int> in
                self.workLog.log(.flatMap)
                return otherEmitter
            })
            .logResults(with: workLog)

        emitter.emit(0)
        otherEmitter.terminate(testError)
        emitter.emit(0)
        otherEmitter.emit(0)
        XCTAssertEqual(workLog, [.flatMap, .terminated(testErrorDescription), .finished, .flatMap])
    }

    func testShouldHandleError_WhenBroadcastingError_WithFlatMap() {
        let otherEmitter = Emitter<Int>()

        emitter
            .flatMap({ (_: Int) -> Futura.Signal<Int> in
                self.workLog.log(.flatMap)
                return otherEmitter
            })
            .logResults(with: workLog)

        otherEmitter.emit(2)
        emitter.emit(testError)
        otherEmitter.emit(1)
        XCTAssertEqual(workLog, [.errors(testErrorDescription)])
    }

    func testShouldHandleError_WhenBroadcastingValue_WithThrowingFlatMap() {
        let otherEmitter = Emitter<Int>()

        emitter
            .flatMap({ (_: Int) -> Futura.Signal<Int> in
                self.workLog.log(.flatMap)
                throw testError
            })
            .logResults(with: workLog)

        otherEmitter.emit(2)
        emitter.emit(0)
        otherEmitter.emit(1)
        XCTAssertEqual(workLog, [.flatMap, .errors(testErrorDescription)])
    }

    func testShouldHandleEnd_WhenClosing_WithFlatMap() {
        let otherEmitter = Emitter<Int>()

        emitter
            .flatMap({ (_: Int) -> Futura.Signal<Int> in
                self.workLog.log(.flatMap)
                return otherEmitter
            })
            .logResults(with: workLog)

        otherEmitter.emit(2)
        emitter.end()
        otherEmitter.emit(1)
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleTerminate_WhenTerminating_WithFlatMap() {
        let otherEmitter = Emitter<Int>()

        emitter
            .flatMap({ (_: Int) -> Futura.Signal<Int> in
                self.workLog.log(.flatMap)
                return otherEmitter
            })
            .logResults(with: workLog)

        otherEmitter.emit(2)
        emitter.terminate(testError)
        otherEmitter.emit(1)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }

    func testShouldHandleEnd_WhenDeallocating_WithFlatMap() {
        let otherEmitter = Emitter<Int>()

        emitter
            .flatMap({ (_: Int) -> Futura.Signal<Int> in
                self.workLog.log(.flatMap)
                return otherEmitter
            })
            .logResults(with: workLog)

        otherEmitter.emit(2)
        emitter = nil
        otherEmitter.emit(1)
        XCTAssertEqual(workLog, [.ended, .finished])
    }
    
    // MARK: -
    
    // MARK: flatMapFuture
    
    func testShouldHandleValue_WhenBroadcastingValue_WithFlatMapFuture_WithValue() {
        let promise: Promise<Int> = .init()
        
        emitter
            .flatMapFuture({ (val: Int) -> Future<Int> in
                self.workLog.log(.flatMapFuture)
                return promise.future.map { $0 + val }
            })
            .logResults(with: workLog)
        
        emitter.emit(1)
        promise.fulfill(with: 1)
        XCTAssertEqual(workLog, [.flatMapFuture, .values(testDescription(of: 2))])
    }
    
    func testShouldHandleError_WhenBroadcastingValue_WithFlatMapFuture_WithError() {
        let promise: Promise<Int> = .init()
        
        emitter
            .flatMapFuture({ (val: Int) -> Future<Int> in
                self.workLog.log(.flatMapFuture)
                return promise.future.map { $0 + val }
            })
            .logResults(with: workLog)
        
        emitter.emit(1)
        promise.break(with: testError)
        XCTAssertEqual(workLog, [.flatMapFuture, .errors(testErrorDescription)])
    }
    
    func testShouldHandleEnded_WhenBroadcastingValue_WithFlatMapFuture_WithCancel() {
        let promise: Promise<Int> = .init()
        
        emitter
            .flatMapFuture({ (val: Int) -> Future<Int> in
                self.workLog.log(.flatMapFuture)
                return promise.future.map { $0 + val }
            })
            .logResults(with: workLog)
        
        emitter.emit(0)
        promise.cancel()
        emitter.emit(0)
        XCTAssertEqual(workLog, [.flatMapFuture, .flatMapFuture])
    }
    
    func testShouldHandleError_WhenBroadcastingError_WithFlatMapFuture() {
        let promise: Promise<Int> = .init()
        
        emitter
            .flatMapFuture({ (val: Int) -> Future<Int> in
                self.workLog.log(.flatMapFuture)
                return promise.future.map { $0 + val }
            })
            .logResults(with: workLog)
        
        
        emitter.emit(testError)
        promise.fulfill(with: 1)
        XCTAssertEqual(workLog, [.errors(testErrorDescription)])
    }
    
    func testShouldHandleError_WhenBroadcastingValue_WithThrowingFlatMapFuture() {
        emitter
            .flatMapFuture({ (val: Int) -> Future<Int> in
                self.workLog.log(.flatMapFuture)
                throw testError
            })
            .logResults(with: workLog)
        
        emitter.emit(0)
        XCTAssertEqual(workLog, [.flatMapFuture, .errors(testErrorDescription)])
    }
    
    func testShouldHandleEnd_WhenClosing_WithFlatMapFuture() {
        let promise: Promise<Int> = .init()
        
        emitter
            .flatMapFuture({ (val: Int) -> Future<Int> in
                self.workLog.log(.flatMapFuture)
                return promise.future.map { $0 + val }
            })
            .logResults(with: workLog)
        
        emitter.end()
        promise.fulfill(with: 0)
        XCTAssertEqual(workLog, [.ended, .finished])
    }
    
    func testShouldHandleTerminate_WhenTerminating_WithFlatMapFuture() {
        let promise: Promise<Int> = .init()
        
        emitter
            .flatMapFuture({ (val: Int) -> Future<Int> in
                self.workLog.log(.flatMapFuture)
                return promise.future.map { $0 + val }
            })
            .logResults(with: workLog)
        
        emitter.terminate(testError)
        promise.fulfill(with: 0)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }
    
    func testShouldHandleEnd_WhenDeallocating_WithFlatMapFuture() {
        let promise: Promise<Int> = .init()
        
        emitter
            .flatMapFuture({ (val: Int) -> Future<Int> in
                self.workLog.log(.flatMapFuture)
                return promise.future.map { $0 + val }
            })
            .logResults(with: workLog)
        
        emitter = nil
        promise.fulfill(with: 0)
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    // MARK: -

    // MARK: collector

    func testShouldHandleValue_WhenBroadcastingValue_WithCollector() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .collect(with: collector)
            .logResults(with: workLog)

        emitter.emit(0)
        collector = nil
        emitter.emit(0)
        XCTAssertEqual(workLog, [.values(testDescription(of: 0))])
    }

    func testShouldHandleError_WhenBroadcastingError_WithCollector() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .collect(with: collector)
            .logResults(with: workLog)

        emitter.emit(testError)
        collector = nil
        emitter.emit(testError)
        XCTAssertEqual(workLog, [.errors(testErrorDescription)])
    }

    func testShouldHandleEnd_WhenClosing_WithCollector() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .collect(with: collector)
            .logResults(with: workLog)

        emitter.end()
        collector = nil
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleTerminate_WhenTerminating_WithCollector() {
        let collector: SubscriptionCollector! = .init()

        emitter
            .collect(with: collector)
            .logResults(with: workLog)

        emitter.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }

    func testShouldHandleEnd_WhenDeallocating_WithCollector() {
        let collector: SubscriptionCollector! = .init()

        emitter
            .collect(with: collector)
            .logResults(with: workLog)

        emitter = nil
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldNotHandle_WhenClosing_WithCollector() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .collect(with: collector)
            .logResults(with: workLog)

        collector = nil
        emitter.end()
        XCTAssertEqual(workLog, [])
    }

    func testShouldNotHandle_WhenTerminating_WithCollector() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .collect(with: collector)
            .logResults(with: workLog)

        collector = nil
        emitter.terminate(testError)
        XCTAssertEqual(workLog, [])
    }

    func testShouldNotHandle_WhenDeallocating_WithCollector() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .collect(with: collector)
            .logResults(with: workLog)

        collector = nil
        emitter = nil
        XCTAssertEqual(workLog, [])
    }

    func testShouldHandleValue_WhenBroadcastingValue_WithCollectorAndTransformations() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .collect(with: collector)
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .logResults(with: workLog)

        emitter.emit(0)
        collector = nil
        emitter.emit(0)
        XCTAssertEqual(workLog, [.map, .map, .values(testDescription(of: 0)), .map])
    }

    func testShouldHandleError_WhenBroadcastingError_WithCollectorAndTransformations() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .collect(with: collector)
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .logResults(with: workLog)

        emitter.emit(testError)
        collector = nil
        emitter.emit(testError)
        XCTAssertEqual(workLog, [.errors(testErrorDescription)])
    }

    func testShouldHandleEnd_WhenClosing_WithCollectorAndTransformations() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .collect(with: collector)
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .logResults(with: workLog)

        emitter.end()
        collector = nil
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleTerminate_WhenTerminating_WithCollectorAndTransformations() {
        let collector: SubscriptionCollector! = .init()

        emitter
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .collect(with: collector)
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .logResults(with: workLog)

        emitter.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }

    func testShouldHandleEnd_WhenDeallocating_WithCollectorAndTransformations() {
        let collector: SubscriptionCollector! = .init()

        emitter
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .collect(with: collector)
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .logResults(with: workLog)

        emitter = nil
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldNotHandle_WhenClosing_WithCollectorAndTransformations() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .collect(with: collector)
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .logResults(with: workLog)

        collector = nil
        emitter.end()
        XCTAssertEqual(workLog, [])
    }

    func testShouldNotHandle_WhenTerminating_WithCollectorAndTransformations() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .collect(with: collector)
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .logResults(with: workLog)

        collector = nil
        emitter.terminate(testError)
        XCTAssertEqual(workLog, [])
    }

    func testShouldNotHandle_WhenDeallocating_WithCollectorAndTransformations() {
        var collector: SubscriptionCollector! = .init()

        emitter
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .collect(with: collector)
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value
            }
            .logResults(with: workLog)

        collector = nil
        emitter = nil
        XCTAssertEqual(workLog, [])
    }

    // MARK: -

    // MARK: workerSwitch

    func testShouldHandleValue_WhenBroadcastingValue_WithWorkerSwitch() {
        let worker: TestWorker = .init()

        emitter
            .switch(to: worker)
            .logResults(with: workLog)

        emitter.emit(0)
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.values(testDescription(of: 0))])
    }

    func testShouldHandleError_WhenBroadcastingError_WithWorkerSwitch() {
        let worker: TestWorker = .init()

        emitter
            .switch(to: worker)
            .logResults(with: workLog)

        emitter.emit(testError)
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.errors(testErrorDescription)])
    }

    func testShouldHandleEnd_WhenClosing_WithWorkerSwitch() {
        let worker: TestWorker = .init()

        emitter
            .switch(to: worker)
            .logResults(with: workLog)

        emitter.end()
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleTerminate_WhenTerminating_WithWorkerSwitch() {
        let worker: TestWorker = .init()

        emitter
            .switch(to: worker)
            .logResults(with: workLog)

        emitter.terminate(testError)
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }

    func testShouldHandleEnd_WhenDeallocating_WithWorkerSwitch() {
        let worker: TestWorker = .init()

        emitter
            .switch(to: worker)
            .logResults(with: workLog)

        emitter = nil
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleValuesAndErrors_WithTransformations() {
        var collector: SubscriptionCollector! = .init()
        let worker: TestWorker = .init()

        emitter
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value + 1
            }
            .logResults(with: workLog)
            .switch(to: worker)
            .logResults(with: workLog)
            .collect(with: collector)
            .map { (value) -> Int in
                self.workLog.log(.map)
                return value + 1
            }
            .logResults(with: workLog)

        emitter.emit(0)
        worker.execute()
        emitter.emit(testError)
        worker.execute()
        collector = nil
        worker.execute()
        emitter.emit(0)
        worker.execute()
        emitter.emit(testError)
        worker.execute()
        emitter.terminate(testError)
        worker.execute()
        XCTAssertEqual(workLog, [
            .map,
            .values(testDescription(of: 1)),
            .values(testDescription(of: 1)),
            .map,
            .values(testDescription(of: 2)),
            .errors(testErrorDescription),
            .errors(testErrorDescription),
            .errors(testErrorDescription),
            .map,
            .values(testDescription(of: 1)),
            .values(testDescription(of: 1)),
            .errors(testErrorDescription),
            .errors(testErrorDescription),
            .terminated(testErrorDescription),
            .finished,
            .terminated(testErrorDescription),
            .finished,
        ])
    }

    // MARK: -

    // MARK: filter

    func testShouldHandleValue_WhenBroadcastingValue_WithFilterPassing() {
        emitter
            .filter {
                let result = $0 == 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)

        emitter.emit(0)
        XCTAssertEqual(workLog, [.filter(true), .values(testDescription(of: 0))])
    }

    func testShouldNotHandle_WhenBroadcastingValue_WithFilterNotPassing() {
        emitter
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)

        emitter.emit(0)
        XCTAssertEqual(workLog, [.filter(false)])
    }

    func testShouldHandleError_WhenBroadcastingError_WithFilter() {
        emitter
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)

        emitter.emit(testError)
        XCTAssertEqual(workLog, [.errors(testErrorDescription)])
    }

    func testShouldHandleEnd_WhenClosing_WithFilter() {
        emitter
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)

        emitter.end()
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleTerminate_WhenTerminating_WithFilter() {
        emitter
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)

        emitter.terminate(testError)
        XCTAssertEqual(workLog, [.terminated(testErrorDescription), .finished])
    }

    func testShouldHandleEnd_WhenDeallocating_WithFilter() {
        emitter
            .filter {
                let result = $0 != 0
                self.workLog.log(.filter(result))
                return result
            }
            .logResults(with: workLog)

        emitter = nil
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldHandleValues_WhenBroadcastingValues_WithDuplicateFilter() {
        emitter
            .filterDuplicates()
            .logResults(with: workLog)

        emitter.emit(0)
        emitter.emit(0)
        emitter.emit(1)
        emitter.emit(0)
        emitter.emit(0)
        emitter.emit(1)
        XCTAssertEqual(workLog, [
            .values(testDescription(of: 0)),
            .values(testDescription(of: 1)),
            .values(testDescription(of: 0)),
            .values(testDescription(of: 1)),
        ])
    }

    func testShouldHandleValues_WhenBroadcastingValues_WithCustomDuplicateFilter() {
        emitter
            .filterDuplicates {
                $0 == $1
            }
            .logResults(with: workLog)

        emitter.emit(0)
        emitter.emit(0)
        emitter.emit(1)
        emitter.emit(0)
        emitter.emit(0)
        emitter.emit(1)
        XCTAssertEqual(workLog, [
            .values(testDescription(of: 0)),
            .values(testDescription(of: 1)),
            .values(testDescription(of: 0)),
            .values(testDescription(of: 1)),
        ])
    }

    // MARK: -

    // MARK: merge

    func testShouldHandleValue_WhenBroadcastingValue_WithMerge() {
        let first: Emitter<String> = .init()
        let second: Emitter<String> = .init()
        let third: Emitter<String> = .init()
        merge(first, second, third)
            .logResults(with: workLog)

        first.emit("first")
        second.emit("second")
        third.emit("third")
        second.emit("second")
        first.emit("first")
        XCTAssertEqual(workLog, [
            .values(testDescription(of: "first")),
            .values(testDescription(of: "second")),
            .values(testDescription(of: "third")),
            .values(testDescription(of: "second")),
            .values(testDescription(of: "first")),
        ])
    }

    func testShouldHandleError_WhenBroadcastingError_WithMerge() {
        let first: Emitter<String> = .init()
        let second: Emitter<String> = .init()
        let third: Emitter<String> = .init()
        merge(first, second, third)
            .logResults(with: workLog)

        first.emit(testError)
        second.emit(testError)
        third.emit(testError)
        second.emit(testError)
        first.emit(testError)
        XCTAssertEqual(workLog, [
            .errors(testErrorDescription),
            .errors(testErrorDescription),
            .errors(testErrorDescription),
            .errors(testErrorDescription),
            .errors(testErrorDescription),
        ])
    }

    func testShouldHandleEnd_WhenClosing_WithMerge() {
        let first: Emitter<Void> = .init()
        let second: Emitter<Void> = .init()
        let third: Emitter<Void> = .init()
        merge(first, second, third)
            .logResults(with: workLog)

        first.emit()
        second.emit()
        third.emit()
        second.end()
        third.emit()
        second.emit()
        first.emit()
        XCTAssertEqual(workLog, [
            .values(testDescription(of: Void())),
            .values(testDescription(of: Void())),
            .values(testDescription(of: Void())),
            .ended,
            .finished,
        ])
    }

    func testShouldHandleTerminate_WhenTerminating_WithMerge() {
        let first: Emitter<Void> = .init()
        let second: Emitter<Void> = .init()
        let third: Emitter<Void> = .init()
        merge(first, second, third)
            .logResults(with: workLog)

        first.emit()
        second.emit()
        third.emit()
        second.terminate(testError)
        third.emit()
        second.emit()
        first.emit()
        XCTAssertEqual(workLog, [
            .values(testDescription(of: Void())),
            .values(testDescription(of: Void())),
            .values(testDescription(of: Void())),
            .terminated(testErrorDescription),
            .finished,
        ])
    }

    func testShouldHandleEnd_WhenDeallocating_WithMerge() {
        let first: Emitter<Void> = .init()
        var second: Emitter<Void>! = .init()
        let third: Emitter<Void> = .init()
        merge(first, second, third)
            .logResults(with: workLog)

        first.emit()
        second.emit()
        third.emit()
        second = nil
        third.emit()
        first.emit()
        XCTAssertEqual(workLog, [
            .values(testDescription(of: Void())),
            .values(testDescription(of: Void())),
            .values(testDescription(of: Void())),
            .ended,
            .finished,
        ])
    }

    func testShouldDeallocateWithMerge() {
        var first: Emitter<Void>! = .init()
        var second: Emitter<Void>! = .init()
        var third: Emitter<Void>! = .init()
        weak var merged = merge(first, second, third)

        XCTAssertNotNil(merged)

        first = nil
        XCTAssertNil(first)

        second = nil
        XCTAssertNil(second)

        third = nil
        XCTAssertNil(third)

        XCTAssertNil(merged)
    }

    // MARK: -

    // MARK: memory

    func testShouldDeallocateWithoutHandlers() {
        var emitter: Emitter<Int>? = Emitter<Int>()
        weak var signal = emitter?.signal

        XCTAssertNotNil(signal)

        emitter = nil

        XCTAssertNil(signal)
    }

    func testShouldDeallocateWithHandlers() {
        var emitter: Emitter<Int>? = Emitter<Int>()
        weak var signal = emitter?.signal
        signal?.logResults(with: workLog)

        XCTAssertNotNil(signal)

        emitter = nil

        XCTAssertNil(signal)
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    func testShouldDeallocateWithTransformations() {
        var emitter: Emitter<Int>? = Emitter<Int>()
        weak var signal = emitter?.signal
        var mapped = emitter?.signal.map { $0 }
        weak var mappedSignal = mapped
        mappedSignal?.logResults(with: workLog)

        XCTAssertNotNil(signal)
        XCTAssertNotNil(mappedSignal)

        emitter = nil

        XCTAssertNil(signal)
        XCTAssertNotNil(mappedSignal)

        mapped = nil

        XCTAssertNil(signal)
        XCTAssertNil(mappedSignal)

        XCTAssertEqual(workLog, [.ended, .finished])
    }

    // MARK: -

    // MARK: thread safety

    // make sure that tests run with thread sanitizer enabled
    func testShouldWorkProperly_WhenAccessingOnManyThreads() {
        asyncTest(iterationTimeout: 5,
                  timeoutBody: {
                      XCTFail("Not in time - possible deadlock or fail")
        }) { complete in
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: RecursiveLock = .init()
            let lock_2: RecursiveLock = .init()
            let lock_3: RecursiveLock = .init()
            var counter_1 = 0
            var counter_2 = 0
            var counter_3 = 0

            dispatchQueue.async {
                lock_1.lock()
                for _ in 0 ..< 100 {
                    self.emitter.values { _ in counter_1 += 1 }
                }
                lock_1.unlock()
            }
            dispatchQueue.async {
                lock_2.lock()
                for _ in 0 ..< 100 {
                    self.emitter.values { _ in counter_2 += 1 }
                }
                lock_2.unlock()
            }
            dispatchQueue.async {
                lock_3.lock()
                for _ in 0 ..< 100 {
                    self.emitter.values { _ in counter_3 += 1 }
                }
                lock_3.unlock()
            }

            sleep(1) // make sure that queue locks first
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            self.emitter.emit(0)

            XCTAssertEqual(counter_1 + counter_2 + counter_3, 300, "Calls count not matching expected")
            complete()
        }
    }
}

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

    // MARK: Access

    func testShouldHandleValue_WhenBroadcastingValue() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
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
        XCTAssertEqual(workLog, [.values(testDescription(of: 0))])
    }

    func testShouldHandleError_WhenBroadcastingError() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
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
        XCTAssertEqual(workLog, [.errors(testErrorDescription)])
    }

    func testShouldHandleClose_WhenClosing() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
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

    func testShouldHandleClose_WhenAlreadyClosed() {
        emitter.end()
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
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

    func testShouldHandleClose_WhenDeallocating() {
        emitter.signal
            .values {
                self.workLog.log(.values(testDescription(of: $0)))
            }
            .errors {
                self.workLog.log(.errors(testDescription(of: $0)))
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

    // MARK: Map

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

    func testShouldHandleClose_WhenClosing_WithMap() {
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

    func testShouldHandleClose_WhenDeallocating_WithMap() {
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

    // MARK: FlatMap

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

    func testShouldHandleended_WhenBroadcastingValue_WithFlatMap_WithClose() {
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

    func testShouldHandleClose_WhenClosing_WithFlatMap() {
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

    func testShouldHandleClose_WhenDeallocating_WithFlatMap() {
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

    // MARK: Collector

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

    func testShouldHandleClose_WhenClosing_WithCollector() {
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

    func testShouldHandleClose_WhenDeallocating_WithCollector() {
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

    func testShouldHandleClose_WhenClosing_WithCollectorAndTransformations() {
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

    func testShouldHandleClose_WhenDeallocating_WithCollectorAndTransformations() {
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

    // MARK: WorkerSwitch

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

    func testShouldHandleClose_WhenClosing_WithWorkerSwitch() {
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

    func testShouldHandleClose_WhenDeallocating_WithWorkerSwitch() {
        let worker: TestWorker = .init()

        emitter
            .switch(to: worker)
            .logResults(with: workLog)

        emitter = nil
        XCTAssertEqual(workLog, [])
        worker.execute()
        XCTAssertEqual(workLog, [.ended, .finished])
    }

    // MARK: -

    // MARK: Filter

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

    func testShouldHandleClose_WhenClosing_WithFilter() {
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

    func testShouldHandleClose_WhenDeallocating_WithFilter() {
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

    // MARK: -

    // MARK: memory

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

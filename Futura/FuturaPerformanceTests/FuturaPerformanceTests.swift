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

class RecursiveLockPerformanceTests: XCTestCase {
    
    func testPerformance_RecursiveLock_LockAndUnlock() {
        let lock = RecursiveLock()
        let count = 1_000_000
        measure {
            for _ in 0 ..< count {
                lock.lock()
                lock.unlock()
            }
        }
    }
    
    func testPerformance_RecursiveLock_Synchronized() {
        let lock = RecursiveLock()
        let count = 1_000_000
        measure {
            for _ in 0 ..< count{
                lock.synchronized {}
            }
        }
    }

    func testPerformance_Schedule_OfFuturaWorkerOnOtherWorker() {
        let count = 1_000_000
        let worker = FuturaWorker()
        measure {
            for _ in 0 ..< count {
                worker.schedule {}
            }
        }
    }

    func testPerformance_Schedule_OfFuturaWorkerOnSelf() {
        let count = 1_000_000
        let worker: FuturaWorker = .init()
        let mtx = Mutex.make(recursive: false)
        Mutex.lock(mtx)
        measure {
            worker.schedule {
                for _ in 0 ..< count {
                    worker.schedule {}
                }
                Mutex.unlock(mtx)
            }
            Mutex.lock(mtx)
        }
        Mutex.destroy(mtx)
    }

    func testPerformance_Schedule_OfDispatchWorkerOnOtherWorker() {
        let count = 1_000_000
        let worker: DispatchWorker = .default
        measure {
            for _ in 0..<count {
                worker.schedule {}
            }
        }
    }

    func testPerformance_Schedule_OfDispatchWorkerOnSelf() {
        let count = 1_000_000
        let worker: DispatchWorker = .default
        let mtx = Mutex.make(recursive: false)
        Mutex.lock(mtx)
        measure {
            worker.schedule {
                for _ in 0 ..< count {
                    worker.schedule {}
                }
                Mutex.unlock(mtx)
            }
            Mutex.lock(mtx)
        }
        Mutex.destroy(mtx)
    }
}

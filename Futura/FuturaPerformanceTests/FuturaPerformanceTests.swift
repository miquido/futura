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

class RecursiveLockPerformanceTests: XCTestCase {

    func testPerformance_LockAndUnlock() {
        let count = 10_000_000
        measure {
            let lock = RecursiveLock()
            var total = 0
            
            for _ in 0 ..< count{
                lock.lock()
                total += 1
                lock.unlock()
            }
            
            XCTAssert(total == 10_000_000)
        }
    }

    func testPerformance_Init_OfFuturaWorker() {
        measure {
            // making a lot of threads is pointless and making too many causes errors - crash
            for _ in 0..<100 {
                _ = FuturaWorker.init()
            }
        }
    }
    
    func testPerformance_Schedule_OfFuturaWorker() {
        let worker = FuturaWorker.init()
        
        measure {
            for _ in 0..<100_000 {
                worker.schedule {}
            }
        }
    }
    
    func testPerformance_Synchronized() {
        let count = 10_000_000
        measure {
            let lock = RecursiveLock()
            var total = 0
            
            for _ in 0 ..< count{
                lock.synchronized { total += 1 }
            }
            
            XCTAssert(total == count)
        }
    }
}

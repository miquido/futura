//
//  FuturaPerformanceTests.swift
//  FuturaPerformanceTests
//
//  Created by Kacper Kaliński on 12/10/2018.
//  Copyright © 2018 Miquido. All rights reserved.
//

import XCTest
import Futura

class FuturaPerformanceTests: XCTestCase {

    func testPerformance_LockAndUnlock_OfLock() {
        measure {
            let lock = Lock()
            var total = 0
            
            for _ in 0..<10_000_000 {
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
            // insert to array is a bottleneck now
            for _ in 0..<100_000 {
                worker.schedule {}
            }
        }
    }
}

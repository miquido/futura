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

    func testPerformance_LockAndUnlock_OfRecursiveLock() {
        let count = 10_000_000
        measure {
            let lock = RecursiveLock()
            var total = 0
            
            for _ in 0 ..< count{
                lock.lock()
                total += 1
                lock.unlock()
            }
            
            XCTAssert(total == count)
        }
    }
    
    func testPerformance_Synchronized_OfRecursiveLock() {
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

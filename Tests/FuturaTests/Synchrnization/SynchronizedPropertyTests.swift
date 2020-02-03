//
//  SynchronizedPropertyTests.swift
//  FuturaTest
//
//  Created by Kacper Kalinski on 1/29/20.
//

import Futura
import FuturaTest
import XCTest

class SynchronizedPropertyTests: XCTestCase {
    
    final class TestClass<T> {
        @Synchronized var testProperty: T
        
        init(testProperty: T) {
            self.testProperty = testProperty
        }
        
        public func synchronized(_ access: (inout T) throws -> Void) rethrows {
            try _testProperty.synchronized(access)
        }
    }
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldNotCauseDataRace_WhenAccessingOnManyThreads() {
        asyncTest { complete in
            let testClass: TestClass<Bool> = TestClass(testProperty: false)
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: Lock = .init()
            let lock_2: Lock = .init()
            let lock_3: Lock = .init()
            
            lock_1.lock()
            dispatchQueue.async {
                for _ in 0 ..< 100 {
                    testClass.testProperty.toggle()
                }
                lock_1.unlock()
            }
            lock_2.lock()
            dispatchQueue.async {
                for _ in 0 ..< 100 {
                    testClass.testProperty.toggle()
                }
                lock_2.unlock()
            }
            lock_3.lock()
            dispatchQueue.async {
                for _ in 0 ..< 100 {
                    testClass.testProperty.toggle()
                }
                lock_3.unlock()
            }
            
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            complete() // there is no assertion since we rely on thread sanitizer to catch errors
        }
    }
    
    // make sure that tests run with thread sanitizer enabled
    func testShouldNotCauseDataRace_WhenAccessingInBlockOnManyThreads() {
        asyncTest { complete in
            let testClass: TestClass<Int> = TestClass(testProperty: 0)
            
            let dispatchQueue: DispatchQueue = DispatchQueue(label: "test", qos: .default, attributes: .concurrent)
            let lock_1: Lock = .init()
            let lock_2: Lock = .init()
            let lock_3: Lock = .init()
            
            lock_1.lock()
            dispatchQueue.async {
                for _ in 0 ..< 100 {
                    testClass.synchronized { $0 += 1 }
                }
                lock_1.unlock()
            }
            lock_2.lock()
            dispatchQueue.async {
                for _ in 0 ..< 100 {
                    testClass.synchronized { $0 += 1 }
                }
                lock_2.unlock()
            }
            lock_3.lock()
            dispatchQueue.async {
                for _ in 0 ..< 100 {
                    testClass.synchronized { $0 += 1 }
                }
                lock_3.unlock()
            }
            
            lock_1.lock()
            lock_2.lock()
            lock_3.lock()
            
            XCTAssertEqual(testClass.testProperty, 300, "Calls count not matching expected")
            complete()
        }
    }
}


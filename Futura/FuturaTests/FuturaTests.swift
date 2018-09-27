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

struct TestError : Error {}

let performanceTestIterations = 10_000_000

extension XCTestCase {
    
    func asyncTest(
        iterationTimeout: TimeInterval = 3,
        iterations: UInt = 1,
        timeoutBody: @escaping ()->(),
        testBody: @escaping (@escaping ()->())->())
    {
        let lock = NSConditionLock()
        let testQueue = DispatchQueue(label: "AsyncTestQueue")
        (0..<iterations).forEach { iteration in
            lock.lock()
            testQueue.async {
                testBody() { lock.unlock() }
            }
            guard lock.lock(before: Date.init(timeIntervalSinceNow: iterationTimeout)) else {
                return timeoutBody()
            }
        }
    }
}

let markedQueueKey = DispatchSpecificKey<Void>()
let markedQueue: DispatchQueue = {
    let queue = DispatchQueue(label: "MarkedQueue")
    queue.setSpecific(key:markedQueueKey, value:())
    return queue
}()

extension DispatchQueue {
    
    static var isOnMarkedQueue: Bool {
        return DispatchQueue.getSpecific(key: markedQueueKey) != nil
    }
}

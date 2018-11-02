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

struct TestError : Error {}

let testError: TestError = TestError()
let testErrorDescription: String = testDescription(of: testError)

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

extension XCTestCase {
    
    func asyncTest(
        iterationTimeout: TimeInterval = 3,
        iterations: UInt = 1,
        timeoutBody: @escaping ()->(),
        testBody: @escaping (@escaping ()->())->())
    {
        let testQueue = DispatchQueue(label: "AsyncTestQueue")
        (0 ..< iterations).forEach { iteration in
            let lock = NSConditionLock()
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

extension Future {
    @discardableResult
    func logResults(with workLog: FutureWorkLog) -> Self {
        self
            .then { value in
                workLog.log(.then(testDescription(of: value)))
            }
            .fail { reason in
                workLog.log(.fail(testDescription(of: reason)))
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
            }
        return self
    }
}

func testDescription(of any: Any) -> String {
    return "\(any):\(type(of: any))"
}

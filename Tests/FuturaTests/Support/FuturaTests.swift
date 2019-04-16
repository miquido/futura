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

struct TestError: Error {}

let testError: TestError = TestError()
let testErrorDescription: String = testDescription(of: testError)

let markedQueueKey = DispatchSpecificKey<Void>()
let markedQueue: DispatchQueue = {
    let queue = DispatchQueue(label: "MarkedQueue")
    queue.setSpecific(key: markedQueueKey, value: ())
    return queue
}()

extension DispatchQueue {
    static var isOnMarkedQueue: Bool {
        return DispatchQueue.getSpecific(key: markedQueueKey) != nil
    }
}

func testDescription(of any: Any) -> String {
    return "\(any):\(type(of: any))"
}

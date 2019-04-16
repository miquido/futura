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
import Dispatch

class WorkerTests: XCTestCase {
    func testShouldPerformTask_WithDispatchQueue_AfterWorkScheduled() {
        asyncTest { complete in
            let worker: Worker = DispatchQueue.global()
            worker.schedule { () -> Void in
                complete()
            }
        }
    }

    func testShouldPerformTasks_WithDispatchQueue_AfterWorkScheduledRecursively() {
        asyncTest { complete in
            let worker: Worker = DispatchQueue.global()
            worker.schedule { () -> Void in
                worker.schedule { () -> Void in
                    worker.schedule { () -> Void in
                        complete()
                    }
                }
            }
        }
    }
    
    func testShouldPerformTask_WithOperationQueue_AfterWorkScheduled() {
        asyncTest { complete in
            let worker: Worker = OperationQueue.init()
            worker.schedule { () -> Void in
                complete()
            }
        }
    }
    
    func testShouldPerformTasks_WithOperationQueue_AfterWorkScheduledRecursively() {
        asyncTest { complete in
            let worker: Worker = OperationQueue.init()
            worker.schedule { () -> Void in
                worker.schedule { () -> Void in
                    worker.schedule { () -> Void in
                        complete()
                    }
                }
            }
        }
    }
}

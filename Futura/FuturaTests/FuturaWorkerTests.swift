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

class FuturaWorkerTests: XCTestCase {

    func testShould_PerformScheduledTask_When_WorkItemIsExecuted() {
        asyncTest(iterationTimeout: 200,
                  timeoutBody: {
                    XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let worker = FuturaWorker()
            worker.schedule { () -> Void in
                print("current1 \(worker.isCurrent)")
                worker.schedule { () -> Void in
                    print("current2 \(worker.isCurrent)")
                    worker.schedule { () -> Void in
                        print("current3 \(worker.isCurrent)")
                    }
                }
            }
            worker.schedule { () -> Void in
                print("current~ \(worker.isCurrent)")
            }
            sleep(2)
            worker.schedule { () -> Void in
                print("current1 \(worker.isCurrent)")
                worker.schedule { () -> Void in
                    print("current2 \(worker.isCurrent)")
                    worker.schedule { () -> Void in
                        print("current3 \(worker.isCurrent)")
                    }
                }
            }
            worker.schedule { () -> Void in
                print("current~ \(worker.isCurrent)")
            }
            
            var worker_strong:FuturaWorker? = FuturaWorker()
            weak var worker_weak = worker_strong
            
            let prom = Promise<Int>()
            prom.future.switch(to: worker_strong!).clone().clone().clone().always {
                print("fut \(worker_weak?.isCurrent ?? false)")
            }
            worker_strong = nil
            XCTAssertNotNil(worker_weak)
            prom.fulfill(with: 0)
            
            
            XCTAssertNotNil(worker_weak)
            sleep(3)
            complete()
        }
    }
}

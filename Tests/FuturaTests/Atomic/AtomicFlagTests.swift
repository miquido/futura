/* Copyright 2019 Miquido
 
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

class AtomicFlagTests: XCTestCase {
    
    var flag: AtomicFlag.Pointer!
    
    override func setUp() {
        flag = AtomicFlag.make()
    }
    
    override func tearDown() {
        AtomicFlag.destroy(flag)
    }
    
    func testShouldBeFalseInitially() {
        XCTAssertFalse(AtomicFlag.readAndSet(flag))
    }
    
    func testShouldBeTrueAfterSet() {
        AtomicFlag.readAndSet(flag)
        XCTAssertTrue(AtomicFlag.readAndSet(flag))
    }
    
    func testShouldBeFalseAfterClear() {
        AtomicFlag.readAndSet(flag)
        AtomicFlag.clear(flag)
        XCTAssertFalse(AtomicFlag.readAndSet(flag))
    }
}

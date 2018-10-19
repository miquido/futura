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

class TestWorker : Worker {
    
    private let lock: Lock = .init()
    private var scheduled: [() -> Void] = []
    
    func schedule(_ work: @escaping () -> Void) {
        lock.synchronized {
            scheduled.append(work)
        }
    }
    
    @discardableResult
    func executeFirst() -> Bool {
        return lock.synchronized {
            guard scheduled.count > 0 else { return false }
            scheduled.removeFirst()()
            return true
        }
    }
    
    @discardableResult
    func executeLast() -> Bool {
        return lock.synchronized {
            guard scheduled.count > 0 else { return false }
            scheduled.removeLast()()
            return true
        }
    }
    
    @discardableResult
    func execute() -> Int {
        return lock.synchronized {
            var count: Int = 0
            while executeFirst() { count += 1 }
            return count
        }
    }
    
    var taskCount: Int {
        return lock.synchronized { scheduled.count }
    }
    
    var isEmpty: Bool {
        return lock.synchronized { scheduled.count == 0 }
    }
}

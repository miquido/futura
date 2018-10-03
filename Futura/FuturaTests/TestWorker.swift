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
    
    func executeFirst() {
        lock.synchronized {
            guard scheduled.count > 0 else { return }
            scheduled.removeFirst()()
        }
    }
    
    func executeLast() {
        lock.synchronized {
            guard scheduled.count > 0 else { return }
            scheduled.removeLast()()
        }
    }
    
    func executeAll() {
        lock.synchronized {
            scheduled.forEach { $0() }
            scheduled.removeAll()
        }
    }
    
    func executeAllAndReturnExecutedCount() -> Int {
        var executedCount = 0
        
        while(!scheduled.isEmpty) {
            executeFirst()
            executedCount+=1
        }
        
        return executedCount
    }
    
    var taskCount: Int {
        return lock.synchronized {
            scheduled.count
        }
    }
}

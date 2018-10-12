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

import Darwin

/// FuturaWorker is associated during its lifetime with exactly one pthread.
/// It guarantees that on each schedule call the same thread will be reused.
/// It is not recommended to create a lot of FuturaWorker instances or recreating those often.
/// Sincie each instance spawns new pthread it may produce unnecesary overhead.
/// 
public final class FuturaWorker : Worker {
    
    fileprivate let thread = FuturaThread()
    
    public init() {}
    
    deinit {
        thread.endAfterCompleting()
    }
    
    /// Assigns given work at the end of queue or executes it immediately if already is current.
    public func schedule(_ work: @escaping () -> Void) {
        if isCurrent {
            work()
        } else {
            Mutex.lock(thread.context.taskMutex)
            defer { Mutex.unlock(thread.context.taskMutex) }
            thread.context.tasks.append(work) // TODO: appending and array is bottleneck now
            ThreadCond.signal(thread.context.cond)
        }
    }
    
    public var isCurrent: Bool {
        return pthread_equal(thread.pthread, pthread_self()) != 0
    }
}

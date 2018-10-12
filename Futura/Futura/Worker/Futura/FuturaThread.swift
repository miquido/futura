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

internal final class FuturaThread {
    
    internal var pthread: UnsafeMutablePointer<_opaque_pthread_t>
    internal let context: ThreadContext
    
    internal init(with context: ThreadContext = .init()) {
        let attr = UnsafeMutablePointer<pthread_attr_t>.allocate(capacity: 1)
        guard pthread_attr_init(attr) == 0 else { fatalError() }
        pthread_attr_setdetachstate(attr, PTHREAD_CREATE_DETACHED)
        
        var pthread: UnsafeMutablePointer<_opaque_pthread_t>!
        let res = pthread_create(&pthread, attr, { (pointer) -> UnsafeMutableRawPointer? in
            let context: ThreadContext = Unmanaged<ThreadContext>.fromOpaque(pointer).takeRetainedValue()
            FuturaThread.run(with: context)
            return nil
        }, Unmanaged.passRetained(context).toOpaque())
        precondition(res == 0, "Unable to create thread: \(res)")
        
        self.pthread = pthread
        self.context = context
    }
    
    internal func endAfterCompleting() {
        AtomicFlag.clear(context.aliveFlag)
        ThreadCond.signal(context.cond)
    }
    
    internal static func run(with context: ThreadContext) {
        AtomicFlag.readAndSet(context.aliveFlag)
        Mutex.unlock(context.threadMutex) // this is wired, but without this unlock it does not run properly... to check
        
        while AtomicFlag.readAndSet(context.aliveFlag) {
            Mutex.lock(context.taskMutex)
            while let task = context.tasks.first {
                context.tasks.removeFirst(1) // TODO: array is bottleneck now
                Mutex.unlock(context.taskMutex)
                task()
                Mutex.lock(context.taskMutex)
            }
            Mutex.unlock(context.taskMutex)
            guard AtomicFlag.readAndSet(context.aliveFlag) else { break }
            ThreadCond.wait(context.cond, with: context.threadMutex)
        }
        Mutex.destroy(context.taskMutex)
        Mutex.destroy(context.threadMutex)
        ThreadCond.destroy(context.cond)
    }
}

internal typealias Task = () -> Void

internal final class ThreadContext {
    
    internal let threadMutex: UnsafeMutablePointer<pthread_mutex_t>
    internal let taskMutex: UnsafeMutablePointer<pthread_mutex_t>
    internal let cond: UnsafeMutablePointer<_opaque_pthread_cond_t>
    internal var aliveFlag: UnsafeMutablePointer<atomic_flag>
    internal var tasks: Array<Task>
    
    internal convenience init() {
        self.init(threadMutex: Mutex.make(recursive: false),
                      taskMutex: Mutex.make(recursive: false),
                      cond: ThreadCond.make(),
                      aliveFlag: AtomicFlag.make(),
                      tasks: [])
    }
    
    internal init(
        threadMutex: UnsafeMutablePointer<pthread_mutex_t>,
        taskMutex: UnsafeMutablePointer<pthread_mutex_t>,
        cond: UnsafeMutablePointer<_opaque_pthread_cond_t>,
        aliveFlag: UnsafeMutablePointer<atomic_flag>,
        tasks: Array<Task>)
    {
        self.threadMutex = threadMutex
        self.taskMutex = taskMutex
        self.cond = cond
        self.aliveFlag = aliveFlag
        self.tasks = tasks
    }
}

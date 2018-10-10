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

public final class FuturaWorker : Worker {
    
    fileprivate var thread: UnsafeMutablePointer<_opaque_pthread_t>! = UnsafeMutablePointer<_opaque_pthread_t>.allocate(capacity: 1)
    fileprivate let context
        = ThreadContext(threadMutex: Mutex.make(recursive: false),
                        taskMutex: Mutex.make(recursive: false),
                        cond: ThreadCond.make(),
                        aliveFlag: AtomicFlag.make(),
                        tasks: [])
    
    public init() {
        setupThread()
    }
    
    fileprivate func setupThread() {
        let attr = UnsafeMutablePointer<pthread_attr_t>.allocate(capacity: 1)
        guard pthread_attr_init(attr) == 0 else { fatalError() }
        pthread_attr_setdetachstate(attr, PTHREAD_CREATE_DETACHED)
        
        let res = pthread_create(&thread, attr, { (pointer) -> UnsafeMutableRawPointer? in
            let context: ThreadContext = Unmanaged<ThreadContext>.fromOpaque(pointer).takeRetainedValue()
            FuturaWorker.run(context: context)
            return nil
        }, Unmanaged.passRetained(context).toOpaque())
        precondition(res == 0, "Unable to create thread: \(res)")
        pthread_attr_destroy(attr)
        attr.deinitialize(count: 1)
        attr.deallocate()
    }
    
    fileprivate static func run(context: ThreadContext) {
        AtomicFlag.readAndSet(context.aliveFlag)
        
        while AtomicFlag.readAndSet(context.aliveFlag) {
            Mutex.lock(context.taskMutex)
            while let task = context.tasks.popLast() {
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
        pthread_exit(pthread_self())
    }
    
    deinit {
        AtomicFlag.clear(context.aliveFlag)
        ThreadCond.signal(context.cond)
    }
    
    public func schedule(_ work: @escaping () -> Void) {
        if isCurrent {
            work()
        } else {
            Mutex.lock(context.taskMutex)
            defer { Mutex.unlock(context.taskMutex) }
            context.tasks.insert(work, at: 0)
            ThreadCond.signal(context.cond)
        }
    }
    
    public var isCurrent: Bool {
        return pthread_equal(thread, pthread_self()) != 0
    }
}

fileprivate typealias Task = () -> Void

fileprivate final class ThreadContext {
    fileprivate let threadMutex: UnsafeMutablePointer<pthread_mutex_t>
    fileprivate let taskMutex: UnsafeMutablePointer<pthread_mutex_t>
    fileprivate let cond: UnsafeMutablePointer<_opaque_pthread_cond_t>
    fileprivate var aliveFlag: UnsafeMutablePointer<atomic_flag>
    fileprivate var tasks: ContiguousArray<Task>
    
    fileprivate init(
        threadMutex: UnsafeMutablePointer<pthread_mutex_t>,
        taskMutex: UnsafeMutablePointer<pthread_mutex_t>,
        cond: UnsafeMutablePointer<_opaque_pthread_cond_t>,
        aliveFlag: UnsafeMutablePointer<atomic_flag>,
        tasks: ContiguousArray<Task>)
    {
        self.threadMutex = threadMutex
        self.taskMutex = taskMutex
        self.cond = cond
        self.aliveFlag = aliveFlag
        self.tasks = tasks
    }
}

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
    
    fileprivate typealias Task = () -> Void
    
    fileprivate var thread: UnsafeMutablePointer<_opaque_pthread_t>! = UnsafeMutablePointer<_opaque_pthread_t>.allocate(capacity: 1)
    fileprivate let threadMutex = UnsafeMutablePointer<_opaque_pthread_mutex_t>.allocate(capacity: 1)
     fileprivate let taskMutex = UnsafeMutablePointer<_opaque_pthread_mutex_t>.allocate(capacity: 1)
    fileprivate let cond = UnsafeMutablePointer<_opaque_pthread_cond_t>.allocate(capacity: 1)
    
    fileprivate var tasks: ContiguousArray<Task> = []
    
    public init() {
        setupMutex(threadMutex)
        setupMutex(taskMutex)
        setupCond(cond)
        setupThread()
    }
    
    fileprivate func setupMutex(_ mtx: UnsafeMutablePointer<_opaque_pthread_mutex_t>) {
        let mtxattr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        guard pthread_mutexattr_init(mtxattr) == 0 else { preconditionFailure() }
        pthread_mutexattr_settype(mtxattr, PTHREAD_MUTEX_NORMAL)
        pthread_mutexattr_setpshared(mtxattr, PTHREAD_PROCESS_PRIVATE)
        guard pthread_mutex_init(mtx, mtxattr) == 0 else { preconditionFailure() }
        pthread_mutexattr_destroy(mtxattr)
        mtxattr.deinitialize(count: 1)
        mtxattr.deallocate()
    }
    
    fileprivate func setupCond(_ cond: UnsafeMutablePointer<_opaque_pthread_cond_t>) {
        let condattr = UnsafeMutablePointer<pthread_condattr_t>.allocate(capacity: 1)
        guard pthread_condattr_init(condattr) == 0 else { preconditionFailure() }
        pthread_cond_init(cond, condattr)
    }
    
    fileprivate func setupThread() {
        let threadBox = ThreadBody(self.run)
        let attr = UnsafeMutablePointer<pthread_attr_t>.allocate(capacity: 1)
        guard pthread_attr_init(attr) == 0 else { fatalError() }
        pthread_attr_setdetachstate(attr, PTHREAD_CREATE_DETACHED)
        
        pthread_mutex_lock(threadMutex)
        let res = pthread_create(&thread, attr, { (pointer) -> UnsafeMutableRawPointer? in
            let threadBox = Unmanaged<ThreadBody>.fromOpaque(pointer).takeRetainedValue()
            threadBox.body()
            return nil
        }, Unmanaged.passRetained(threadBox).toOpaque())
        precondition(res == 0, "Unable to create thread: \(res)")
        
        pthread_mutex_lock(threadMutex)
        pthread_mutex_unlock(threadMutex)
    }
    
    fileprivate func run() {
        pthread_mutex_unlock(threadMutex)
        
        while true {
            pthread_mutex_lock(taskMutex)
            while let task = tasks.popLast() {
                pthread_mutex_unlock(taskMutex)
                task()
                pthread_mutex_lock(taskMutex)
            }
            pthread_mutex_unlock(taskMutex)
            pthread_cond_wait(cond, threadMutex)
        }
        pthread_exit(pthread_self())
    }
    
    deinit {
        pthread_cond_destroy(cond)
        cond.deinitialize(count: 1)
        cond.deallocate()
        
        pthread_mutex_destroy(taskMutex)
        taskMutex.deinitialize(count: 1)
        taskMutex.deallocate()
        
        pthread_mutex_destroy(threadMutex)
        threadMutex.deinitialize(count: 1)
        threadMutex.deallocate()
        
        pthread_kill(thread, 0)
    }
    
    public func schedule(_ work: @escaping () -> Void) {
        if isCurrent {
            work()
        } else {
            pthread_mutex_lock(taskMutex)
            defer { pthread_mutex_unlock(taskMutex) }
            tasks.insert(work, at: 0)
            pthread_cond_signal(cond)
        }
    }
    
    public var isCurrent: Bool {
        return pthread_equal(thread, pthread_self()) != 0
    }
}

private final class ThreadBody {
    let body: () -> Void
    
    init(_ body: @escaping () -> Void) {
        self.body = body
    }
}

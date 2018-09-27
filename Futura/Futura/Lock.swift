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

/// Lock is a simple pthread_mutex wrapper with basic lock functionality
public final class Lock {
    private let mtx = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    
    /// Creates instance of basic lock
    public init() {
        let attr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        guard pthread_mutexattr_init(attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_settype(attr, PTHREAD_MUTEX_NORMAL)
        pthread_mutexattr_setpshared(attr, PTHREAD_PROCESS_PRIVATE)
        guard pthread_mutex_init(mtx, attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_destroy(attr)
        attr.deinitialize(count: 1)
        attr.deallocate()
    }
    
    deinit {
        pthread_mutex_destroy(mtx)
        mtx.deinitialize(count: 1)
        mtx.deallocate()
    }
    
    /// Locks lock if available or waits until unlocked
    public func lock() -> Void {
        pthread_mutex_lock(mtx)
    }
    
    /// Locsk lock if available and returns true or returns false otherwise without locking
    public func tryLock() -> Bool {
        return pthread_mutex_trylock(mtx) == 0
    }
    
    
    /// Unlocks a lock
    public func unlock() -> Void {
        pthread_mutex_unlock(mtx)
    }
    
    /// Execute closure with synchronization on self as lock
    public func synchronized<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}

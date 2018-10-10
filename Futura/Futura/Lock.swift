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

/// Lock is a simple pthread_mutex wrapper with basic recursive lock functionality.
/// It should not be used to synchronize threads from multiple processes.
public final class Lock {
    private let mtx = Mutex.make(recursive: true)
    
    /// Creates instance of recursive lock.
    public init() {}
    
    deinit {
        Mutex.destroy(mtx)
    }
    
    /// Locks if available or waits until unlocked.
    /// Since Lock is recursive it will continue when already locked on same thread.
    public func lock() -> Void {
        Mutex.lock(mtx)
    }
    
    /// Locks if available and returns true or returns false otherwise without locking.
    /// Since Lock is recursive it will returns true when already locked on same thread.
    public func tryLock() -> Bool {
        return Mutex.tryLock(mtx)
    }
    
    
    /// Unlocks a lock.
    public func unlock() -> Void {
        Mutex.unlock(mtx)
    }
    
    /// Execute closure with synchronization on self as lock.
    /// Since Lock is recursive you can call synchronized recursively on same thread.
    public func synchronized<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}

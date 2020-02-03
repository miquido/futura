/* Copyright 2020 Miquido

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

/// Lock is a simple pthread_mutex wrapper with basic lock functionality.
/// It should not be used to synchronize threads from multiple processes.
public final class Lock {

    @usableFromInline
    internal let mtx: Mutex.Pointer = Mutex.make(recursive: false)

    /// Creates instance of lock.
    public init() {}

    deinit {
        Mutex.destroy(mtx)
    }

    /// Locks if possible or waits until unlocked.
    @inlinable
    public func lock() {
        Mutex.lock(mtx)
    }
    
    /// Locks if possible or waits until unlocked.
    /// Throws an error if time condition was not met
    ///
    /// - Parameter timeout: Lock wait timeout in seconds.
    @inlinable
    public func lock(timeout: UInt8) throws -> Void {
        try Mutex.lock(mtx, timeout: timeout)
    }

    /// Locks if possible and returns true or returns false otherwise without locking.
    @inlinable
    public func tryLock() -> Bool {
        return Mutex.tryLock(mtx)
    }

    /// Unlocks a lock.
    @inlinable
    public func unlock() {
        Mutex.unlock(mtx)
    }

    /// Execute closure with synchronization on self as lock.
    /// It will wait until unlocked if locked when calling.
    @inlinable
    public func synchronized<T>(_ block: () throws -> T) rethrows -> T {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        return try block()
    }
}


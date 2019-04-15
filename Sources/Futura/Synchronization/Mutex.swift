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

#if os(Linux)
import Glibc
#else
import Darwin.POSIX
#endif

#if os(Linux)
fileprivate let nSecMsec: __time_t = 1_000_000
fileprivate let mSecSec: __time_t = 1_000 * nSecMsec
#else
fileprivate let nSecMsec: __darwin_time_t = 1_000_000
fileprivate let mSecSec: __darwin_time_t = 1_000 * nSecMsec
#endif

/// pthread_mutex api wrapper
public enum Mutex {
    /// Error thrown on mutex timeout
    public struct Timeout: Error {}
    
    /// pthread_mutex_t pointer type
    public typealias Pointer = UnsafeMutablePointer<pthread_mutex_t>

    /// Creates new instance of pthread_mutex.
    /// It is not automatically managed by ARC. You are responsible
    /// to deallocate it manually by calling destroy function.
    ///
    /// - Parameter recursive: Tells if created mutex should be recursive or not.
    /// - Returns: Pointer to new mutex instance
    @inline(__always)
    public static func make(recursive: Bool) -> Pointer {
        let pointer: UnsafeMutablePointer<pthread_mutex_t> = .allocate(capacity: 1)
        let attr: UnsafeMutablePointer<pthread_mutexattr_t> = .allocate(capacity: 1)
        guard pthread_mutexattr_init(attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_settype(attr, recursive ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_NORMAL)
        pthread_mutexattr_setpshared(attr, PTHREAD_PROCESS_PRIVATE)
        guard pthread_mutex_init(pointer, attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_destroy(attr)
        attr.deinitialize(count: 1)
        attr.deallocate()
        return pointer
    }

    /// Deallocates instance of pthread_mutex
    ///
    /// - Parameter pointer: Pointer to mutex to be destroyed.
    @inline(__always)
    public static func destroy(_ pointer: Pointer) {
        pthread_mutex_destroy(pointer)
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }

    /// Locks on instance of pthread_mutex or waits until unlocked if locked.
    ///
    /// - Parameter pointer: Pointer to mutex to be locked.
    @inline(__always)
    public static func lock(_ pointer: Pointer) {
        pthread_mutex_lock(pointer)
    }
    
    /// Locks on instance of pthread_mutex or waits until unlocked if locked.
    /// Throws an error if time condition was not met
    ///
    /// - Parameter pointer: Pointer to mutex to be locked.
    /// - Parameter timeout: Lock wait timeout in seconds.
    @inline(__always)
    public static func lock(_ pointer: Pointer, timeout: UInt8) throws -> Void {
        #if os(Linux)
        var timeout = __time_t(timeout) * mSecSec
        #else
        var timeout = __darwin_time_t(timeout) * mSecSec
        #endif
        
        var rem = timespec(tv_sec: 0, tv_nsec: 0)
        var req = timespec(tv_sec: 0, tv_nsec: 0)
        while pthread_mutex_trylock(pointer) != 0 {
            req.tv_nsec = timeout < nSecMsec ? timeout : nSecMsec
            while nanosleep(&req, &rem) == EINTR {
                req.tv_nsec = rem.tv_nsec
            }
            timeout -= (req.tv_nsec - rem.tv_nsec)
            if timeout <= 0 {
                throw Timeout()
            } else { continue }
        }
    }

    /// Tries to lock on instance of pthread_mutex. Locks if unlocked or passes if locked.
    ///
    /// - Parameter pointer: Pointer to mutex to be locked.
    /// - Returns: Result of trying to lock. True if succeeded, false otherwise.
    @inline(__always)
    public static func tryLock(_ pointer: Pointer) -> Bool {
        return pthread_mutex_trylock(pointer) == 0
    }

    /// Unlocks on instance of pthread_mutex
    ///
    /// - Parameter pointer: Pointer to mutex to be unlocked.
    @inline(__always)
    public static func unlock(_ pointer: Pointer) {
        pthread_mutex_unlock(pointer)
    }
}
